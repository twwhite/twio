<h1 align="center">
  TWIO Cloud Ecosystem
</h1>

<h4 align="center">A compilation of existing open-source software in a containerized deployment script.</h4>


<p align="center">
  <a href="#included-applications">Default Applications</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#download">Download</a> •
  <a href="#backups">Backing up your data</a>
</p>


## Included Applications

|Application|Source  |Destination |Description| Operational | Backups Working |
--- | --- | ---|---| --- |
|PicoCMS|https://github.com/picocms/Pico|domain.example|Flat file CMS| :heavy_check_mark: | |
|Nextcloud|https://github.com/nextcloud/server|cloud.domain.example|Data servver & cloud app suite| :heavy_check_mark:| |
|Kanboard|https://github.com/kanboard/kanboard|todo.domain.example|Kanban project management tool|:heavy_check_mark:| |
|DokuWiki|https://www.dokuwiki.org/dokuwiki|wiki.domain.example|Self-hosted databaseless Wiki|:heavy_check_mark:| |
|Homer Dashboard|https://github.com/bastienwirtz/homer|apps.domain.example|Dashboard for all apps|:heavy_check_mark:| |
|StandardNotes sync-server|https://github.com/standardnotes/syncing-server-js|notes-sync.domain.example|Encrypted notes syncing server| WIP | |
|StandardNotes web app|https://github.com/standardnotes/web |notes.domain.example|Encrypted notes app| WIP| |

## Configuration

The main configuration files for TWIO are as follows.
**./init/new-server.sh**: 
Run once to:
- Import .env vars to for docker-compose up
- Locally clone any repositories necessary for docker-compose up
- Setup without storing user passwords for, for example, MariaDB
- Init Docker networks
- Setup and enable systemd service for startup.sh
- Run startup.sh

**./init/docker-compose.yml**:
https://docs.docker.com/compose/

**./init/db/01.sql**:
Default init file for MariaDB. Creates necessary databases and grants user priviledges.

The included .env file contains the following variables:

* DOMAIN=  | Default domain name associated with all services
* DEFAULT_SSL_EMAIL=  | Email account used for ACME SSL creation/renewal

An additional db.env file should be created including:

* NEXTCLOUD_MARIADB_PASSWORD=changeme123
* NEXTCLOUD_MARIADB_DB=nextcloud
* NEXTCLOUD_MARIADB_USER=nextcloud_user

## How To Use

High level description of scripts:
* new-server.sh - Downloads applications and places them in their respective folders. Initializes where possible.
* kill-all.sh - KILLS ALL RUNNING DOCKER PROCESSES, REMOVES THEM, AND REMOVES THEIR ASSOCIATED IMAGE. PLEASE DON'T RUN THIS UNLESS YOU KNOW WHAT YOU'RE DOING. THIS IS ONLY USED FOR PROTOTYPING AT THE MOMENT.

To clone and run this application, from your command line:

```bash
# Clone this repository
$ git clone https://github.com/twwhite/twio

# Change directory into the repository
$ cd twio

# Set configurables per the Configuration section above

# Run the New Sever script
$ ./new-server.sh
```

Note: You may need to modify file permissions to permit execute by running chmod +x.


## License

MIT License - Copyright (c) 2021 Tim White

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

> [timwhite.io](https://timwhite.io) &nbsp;&middot;&nbsp;
> GitHub [@twwhite](https://github.com/twwhite) &nbsp;&middot;&nbsp;
> Twitter [@timwhiteio](https://twitter.com/timwhiteio)

