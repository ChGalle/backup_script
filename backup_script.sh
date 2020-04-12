#!/bin/bash
DATE=$(date +%Y-%m-%d-%H%M%S)

for arg in "$@"
do 
    if [ "$arg" == "--help" ] || ["$arg" == "-h"]
    then
        echo"Mögliche Argumente sind:
        -h oder --help      Zeigt diese Hilfe an
        -s                  Gibt die Quellverzeichnisse an. Bitte nicht mit einem / abschließen...
        -b                  Gibt das Backup-Zielverzeichnis an
        -n                  Versetzt eine Nextcloud-Instanz während der Sicherung in den Wartungsmodus
        -m                  Sichert alle SQL-Datenbanken in einem Unterordner
        -a                  Stoppt den Apache-Webserver während des Backups
        -r                  Löscht das Backup Zielverzeichnis vor Erstellung des Backups - Also nur Ein Backup..."
        
        
    fi
exit 0
done

while getopts b:s: option
do
case "${option}"
in
b) BACKUP_DIR=${OPTARG};;
s) SOURCE=${OPTARG};;
esac
done





#################################################################################################################
# Soll eine Nextcloudinstanz gesichert werden, dann den Maintenancemode setzen
for arg in "$@"
do 
    if ["$arg" == "-n"]
    then
        sudo -u www-data php -f /var/www/nextcloud/occ maintenance:mode --on
        echo "Der Wartungsmodus wurde gesetzt."
    fi
done

#################################################################################################################
# Zur Sicherung von Websites - Stoppe den Apache Webserver
for arg in "$@"
do 
    if ["$arg" == "-a"]
    then
        service apache2 stop
        echo "Apache Webserver gestoppt."
    fi
done

#################################################################################################################
# Sollen alte Backups von früheren Backups vorher gelöscht werden, bitte die nächsten Zeilen auskommentieren
for arg in "$@"
do 
    if ["$arg" == "-r"]
    then
        echo "lösche alte Backups"
        if [ -d $BACKUP_DIR ]
        then
            rm -r $BACKUP_DIR
        fi
    fi
done

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
# Erstellung von SQL-Backups
# Erstelle Ordner

for arg in "$@"
do 
    if ["$arg" == "-m"]
    then
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
    fi
done


#################################################################################################################
# Setze Backuprechte auf 600
chmod -R 600 $BACKUP_DIR
find $BACKUP_DIR -type d -print0 | xargs -0 chmod 700
echo "Dateirechte wurden gesetzt"

for arg in "$@"
do 
    if ["$arg" == "-a"]
    then
        service apache2 start
        echo "Apache Webserver gestartet."
    fi
done

for arg in "$@"
do 
    if ["$arg" == "-n"]
    then
        sudo -u www-data php -f /var/www/nextcloud/occ maintenance:mode --off
        echo "Der Wartungsmodus wurde gesetzt."
    fi
done
#################################################################################################################
echo "Das Backupscript ist durchgelaufen."
exit 0
