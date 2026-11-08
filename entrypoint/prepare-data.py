#!/usr/bin/env python3
"""Root startup work. Never recursively chown regular files under the data root.

Directories are held by no-follow descriptors before ownership changes. Seed
files and runtime settings are subsequently created as amp, not handed over
by root. This is intentionally independent of the host's hardlink sysctl.
"""
import os
import pwd
import re
import secrets
import stat

ROOT = "/opt/cubecoders/amp3/data"


def prepare_directory(parent_fd, name, uid, gid, private=False):
    created = False
    try:
        os.mkdir(name, 0o700, dir_fd=parent_fd)
        created = True
    except FileExistsError:
        pass
    fd = os.open(name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                 dir_fd=parent_fd)
    try:
        info = os.fstat(fd)
        if private and not created and (info.st_uid != 0 or stat.S_IMODE(info.st_mode) != 0o700):
            raise RuntimeError(f"{name} must already be a root-owned 0700 directory")
        # Directories cannot be hardlinked by an unprivileged process.
        # fchown acts on the opened directory, never on a substituted pathname.
        os.fchown(fd, uid, gid)
        os.fchmod(fd, 0o700 if private else 0o750)
    finally:
        os.close(fd)


def main():
    account = pwd.getpwnam("amp")
    parent_fd = os.open("/opt/cubecoders/amp3",
                        os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        prepare_directory(parent_fd, "data", account.pw_uid, account.pw_gid)
        root_fd = os.open("data", os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                          dir_fd=parent_fd)
    finally:
        os.close(parent_fd)
    try:
        for name in ("versions", "run", "logs", "system", "Datastores", "nats"):
            prepare_directory(root_fd, name, account.pw_uid, account.pw_gid)
        prepare_directory(root_fd, "sysagent", 0, 0, private=True)

        identity_name = ".docker-machine-id"
        try:
            fd = os.open(identity_name, os.O_WRONLY | os.O_CREAT | os.O_EXCL |
                         os.O_NOFOLLOW, 0o444, dir_fd=root_fd)
        except FileExistsError:
            fd = None
        if fd is not None:
            try:
                os.write(fd, (secrets.token_hex(16) + "\n").encode("ascii"))
                os.fsync(fd)
            finally:
                os.close(fd)
        fd = os.open(identity_name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
                     dir_fd=root_fd)
        try:
            info = os.fstat(fd)
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
                raise RuntimeError("Stored machine ID must be a single-link regular file")
            identity = os.read(fd, 128).decode("ascii").strip()
        finally:
            os.close(fd)
        if not re.fullmatch(r"[0-9a-fA-F]{32}", identity):
            raise RuntimeError("Stored machine ID is invalid")
        with open("/etc/machine-id", "w", encoding="ascii") as output:
            output.write(identity + "\n")
    finally:
        os.close(root_fd)


if __name__ == "__main__":
    main()
