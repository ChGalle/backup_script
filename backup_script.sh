#!/bin/bash
DATE=$(date +%Y-%m-%d-%H%M%S)

# pfad sollte nicht mit "/" enden!
# Dies ist nur ein Beispiel - bitte an eigene Bedürfnisse anpassen.
# Man muß schreibberechtigt im entsprechenden Verzeichnis sein.
BACKUP_DIR="/root/backup"

# Hier Verzeichnisse auflisten, die gesichert werden sollen.
# Dies ist nur ein Beispiel - bitte an eigene Bedürfnisse anpassen.
# Bei Verzeichnissen, für die der User keine durchgehenden Leserechte hat (z.B. /etc) sind Fehler vorprogrammiert.
# Pfade sollte nicht mit "/" enden!
SOURCE="$HOME/bin /var/www /var/lib/nextcloud /etc /root/bin"
#################################################################################################################
# Soll eine Nextcloudinstanz gesichert werden, dann den Maintenancemode setzen
#sudo -u www-data php -f /var/www/nextcloud/occ maintenance:mode --on
#echo "Der Wartungsmodus wurde gesetzt."
#################################################################################################################
# Zur Sicherung von Websites - Stoppe den Apache Webserver
service apache2 stop
echo "Apache Webserver gestoppt."
#################################################################################################################
# Sollen alte Backups von früheren Backups vorher gelöscht werden, bitte die nächsten Zeilen auskommentieren

#echo "lösche alte Backups"

#if [ -d $BACKUP_DIR ]
#then
#    rm -r $BACKUP_DIR
#fi
#################################################################################################################
# Erstelle das Backupverzeichnis, sofern es noch nicht angelegt wurde
echo "Erzeuge Backupverzeichnis."

if [ ! -d $BACKUP_DIR ]
then
    mkdir $BACKUP_DIR
fi
#################################################################################################################
# Erstelle das Backup
echo "Archiv wird erstellt."
tar -cjpf $BACKUP_DIR/backup-$DATE.tar.bz2 $SOURCE
#################################################################################################################
# Zur Erstellung von SQL-Backups bitte den nächtsten Abschnitt auskommentieren
# Erstelle Ordner
if [ ! -d $BACKUP_DIR/datenbanken-$DATE ]
then
mkdir $BACKUP_DIR/datenbanken-$DATE
fi

echo "SQL-Dump wird erstellt."
DATABASES=`mysql -Bse 'show databases'`
for DATABASE in $DATABASES; do
    if [ "$DATABASE" != "information_schema" ]; then
        mysqldump --skip-lock-tables $DATABASE > $BACKUP_DIR/datenbanken-$DATE/${DATABASE}.sql
    fi
done
#################################################################################################################
# Setze Backuprechte auf 600
chmod -R 600 $BACKUP_DIR
find $BACKUP_DIR -type d -print0 | xargs -0 chmod 700
echo "Dateirechte wurden gesetzt"

#service apache2 start
#echo "Apache Webserver gestartet."
sudo -u www-data php -f /var/www/nextcloud/occ maintenance:mode --off
echo "Der Wartungsmodus wurde deaktiviert."
#################################################################################################################
# Falls das Backupverzeichnis noch an einen weiteren Ort synchronisiert werden soll, kann dies hier mit rsync geschehen.
# echo "rsync wird ausgeführt."
# rsync -za $BACKUP_DIR /foo/bar/Backups 
