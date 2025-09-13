docker run -d \
  --name amp \
  --restart unless-stopped \
  --network bridge \
  --mac-address 02:42:AC:XX:XX:XX \ # See README for MAC address info
  -p 8080:8080 \                  # AMP Web UI
  # Uncomment the ports below as needed for whatever game servers you'll be running.
  # -p 34197:34197/udp \          # Factorio
  # -p 27015:27015/udp \          # GMod, TF2, and other Source engine games
  # -p 19132:19132/udp \          # Minecraft Bedrock Edition
  # -p 25565:25565 \              # Minecraft Java Edition
  # -p 21025:21025 \              # Starbound
  # -p 5678-5680:5678-5680/udp \  # Valheim
  -v $(pwd)/ampdata:/home/amp/ \
  -e UID=120 \
  -e GID=124 \
  -e TZ=Etc/UTC \
  mitchtalmadge/amp-dockerized:latest
