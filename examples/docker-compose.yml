services:
  amp:
    container_name: amp
    image: mitchtalmadge/amp-dockerized:latest
    networks:
      default:
        mac_address: 02:42:AC:XX:XX:XX # Please see the README about this field.
    ports:
      - 8080:8080                       # AMP Web UI
      # Uncomment the ports below as needed for whatever game servers you'll be running.
      # - 34197:34197/udp               # Factorio
      # - 27015:27015/udp               # GMod, TF2, and other Source engine games
      # - 19132:19132/udp               # Minecraft Bedrock Edition
      # - 25565:25565                   # Minecraft Java Edition
      # - 21025:21025                   # Starbound
      # - 5678-5680:5678-5680/udp       # Valheim
    volumes:
      - ./ampdata:/home/amp/
    environment:
      - "UID=120" # Change according to which user on the host will own the ampdata volume.
      - "GID=124"
      - "TZ=Etc/UTC" # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    restart: unless-stopped