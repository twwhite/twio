CREATE DATABASE IF NOT EXISTS `nextcloud`;
GRANT ALL ON `nextcloud`.* TO 'nextcloud'@'%';

CREATE DATABASE IF NOT EXISTS `kanboard`;
CREATE USER kanboard IDENTIFIED BY 'db_kanboard_pass';
GRANT ALL ON `kanboard`.* TO 'kanboard'@'%';
