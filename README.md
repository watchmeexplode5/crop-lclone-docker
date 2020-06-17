# Rclone - MergerFS - Cloudplow (BETA)


A Docker image modified from [Sabrsorensen's work](https://github.com/sabrsorensen/alpine-cloudplow). This image provides [Rclone with automount Mount](https://github.com/rclone/rclone), [MergerFS](https://github.com/trapexit/mergerfs), and [Cloudplow ](https://github.com/l3uddz/cloudplow) together. 

STILL IN TESTING PHASE BUT FUNCTIONS AS EXPECTED
To do: Restart configured Dockers if rclone mount goes down and remounts (to avoid other dependant dockers not see the mount). Possible use of SLAVE/SHARED drive option but limiting based on system.

## Application

[Rclone](https://github.com/rclone/rclone)

[MergerFS](https://github.com/trapexit/mergerfs)

[Cloudplow](https://github.com/l3uddz/cloudplow)

## Description

When the container starts: Rclone will auto-mount your specified disks and create a union of your cloud + local files via MergerFS.
Cloudplow will automatic trigger remote uploads to your drive (support for scheduled transfers, multiple remote/folder pairings, UnionFS control file cleanup, synchronization between rclone remotes, and service account rotation).

## Usage


Shared-Drives: Utilized with service account rotation utilized for by-passing single user upload limits.
Remote Drive Mover: Utilized to move all shared-drive files to standard Drive. Beside by-passing 400K object limit. Performance from shared-drive suffered exponentially with object count. Performance decrease was noticed at as few as 50K objects, therefore it's best to utilize shared-drives as a simple landing pad. Following upload, objects are immediately moved to a defined Google drive. 

Sample docker-compose.yml configuration, where the host's rclone.conf is stored in ~/.config/rclone, one or more Google Drive service account .json files is located in ~/google_drive_service_accounts, and media to upload is stored in /imported_media:

```yaml
cloudplow:
  image: XXXXXXXX/rclone-mergerfs-cloudplow
  container_name: cloudplow
  environment:
    - RCLONE_REMOTE_MOUNT=google_crypt:
    - RCLONE_LANDING_MOUNT=team_drive_crypt:
    - LANDING_LOCATION=/cloudplow/landing_pad/media
  volumes:
    - /opt/cloudplow:/config/:rw
    - /home/<user>/.config/rclone:/rclone_config/:rw
    - /home/<user>/google_drive_service_accounts:/service_accounts/:rw
    - /mnt/<user>/cloudplow:/cloudplow:rw
    - /etc/localtime:/etc/localtime:ro
  restart: unless-stopped
```
Other Optional Environment Variables: (If not set on run, docker will be built with defaults which are listed below)
```

###Identifier Options:
'PUID'='1000'
'PGID'='1000'

###Cloudplow Options:
'CLOUDPLOW_LOGLEVEL'='DEBUG'
'CLOUDPLOW_CONFIG'='/config/config.json'
'CLOUDPLOW_CACHEFILE'='/config/cache.db'
'CLOUDPLOW_LOGFILE'='/config/cloudplow.log'

###Location Options:
'LOCAL_LOCATION'='/cloudplow/local'
'CLOUD_LOCATION'='/cloudplow/cloud/'
'LANDING_LOCATION'='/cloudplow/landing_pad'
'UNION_LOCATION'='/cloudplow/union'
'MEDIA_SUBFOLDER'='/media'

###Rclone and MergerFS Options:
'RCLONE_MOUNT_OPTIONS='--allow-other --buffer-size 256M --dir-cache-time 1000h --log-level INFO --log-file /config/rclone.log --poll-interval 15s --timeout 1h'
'MERGERFS_OPTIONS='-o rw,async_read=false,use_ino,allow_other,func.getattr=newest,category.action=all,category.create=ff,cache.files=off,dropcacheonclose=true'

```

Upon first run, the container will generate a sample config.json in the container's /config. Edit this config.json to your liking. Be sure to set rclone_config_path to the location of the rclone.conf you mapped into the container. 

Examples of configured files provided in the "examples_config_folder" on the github project page.

Folder structure to ensure ease of setup:

```
cloudplow
    │
    ├── cloud (Google Drive Mount)
    │     └── media
    │           ├── movies
    │           ├── music
    │           └── tv
    │
    ├── landing_pad (Team Drive Mount)
    │
    ├── local
    │     ├── media
    │     │     ├── movies
    │     │     ├── music
    │     │     └── tv
    │     │
    │     └── downloads
    │             ├── manual_downloads
    │             │
    │             ├── nzb_downloads
    │             │           ├── completed
    │             │           └── incompleted
    │             │
    │             └── torrent_downloads
    │                         ├── completed
    │                         └── incompleted
    │
    │
    └── union (Gdrive + Tdrive + Local)
          ├── media
          │     ├── movies
          │     ├── music
          │     └── tv
          │
          └── downloads
```


Easy Mapping Guide for Dockers (For proper atomic-moves/hardlinkning):


```
Reference: HOST PATH <----> CONTAINER PATH

Media Servers:
/host/cloudplow/union <----> /cloudplow/union

Sonarr/Radarr/Lidarr:
/host/cloudplow/union <----> /cloudplow/union/

NZBs:	
/host/cloudplow/local/downloads/nzb_downloads <----> /cloudplow/union/downloads/nzb_downloads

Torrents: 
/host/cloudplow/local/downloads/torrents_downloads <----> /cloudplow/union/downloads/torrents_downloads
```

Union acheived through MergerFS. By default this will merger the cloud google drive, team drive, and local drive into a folder labeled union. When writes occur within union they will be written to the local drive temporarily then moved to their respected location via cloudplow.




Please refer to the official [cloudplow](https://github.com/l3uddz/cloudplow) documentation for additional information on how to configure cloudplow.
