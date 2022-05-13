# Plugin CatLocSudoc pour Koha

## Description  

Ce plugin permet de signaler si l'ouvrage en cours de réception doit être localisé dans le Sudoc ou catalogué.  
Lorsque c'est le cas une alerte apparait en haut de la page. 

## Prérequis

* Koha version 19.11 et plus.
* Pour une version < 20.05, la syspref *UseKohaPlugins* (Contenus enrichis) doit être activée.
* Dans le fichier de configuration de Koha, vous devez également activer l'utilisation des plugins :

      <enable_plugins>1</enable_plugins>

* Enfin, les utilisateurs doivent avoir la permission d'utiliser les plugins Outils.

## Téléchargement

Téléchargez le fichier  [CatLocSudoc-master.zip](https://github.com/oliviercrouzet/catlocsudoc/archive/refs/heads/master.zip) puis renommez l'extension _zip_ en _kpz_ (CatLocSudoc-master.kpz).

## Installation

### via l'interface web

Rendez vous ensuite dans l'interface Koha :  _Outils/Outils de plugins : Télécharger un plugin_

Il n'est pas exclu que vous obteniez un message d'erreur "Impossible de décompresser le fichier dans le répertoire des plugins" même si les permissions du répertoire sont correctes.  
Si c'est le cas, il faudra installer directement sur le serveur.

### sur le serveur

1. Transférer le fichier kpz (= fichier zip) sur le serveur puis :

       cd /home/koha/var/lib/plugins 
       unzip CatLocSudoc-plugin.kpz

2. Lancer le script biblibre plugins.sh

       ~/tools/koha/plugin.sh --db-refresh

### configuration

Dans l'interface Koha/Outils :  
_Outils de plugins/Visualiser les plugins de la classe/Afficher tous les plugins_  
Vous devez maintenant voir le nom du plugin s'afficher. Il ne reste plus qu'à renseigner le rcr.

## Déinstallation

en ligne de commande :

    rm -r [PLUGIN_PATH]/Monplugin*
    exemple :
    rm -r ~/var/lib/plugins/Koha/Plugin/PifPafPlug/CatLocSudoc*
    ~/tools/koha/plugin.sh --db-refresh
	
## Utilisation coordonnée avec un script de localisation dans winIBW

Lorsque le plugin repère un document à localiser, il affiche dans l'alerte le biblionumber et le ppn déja préselectionnés.  
Un Ctrl+C ou Edtion/Copier envoie alors la chaine dans le presse-papier utilisé comme pont, faute de mieux, avec WinIBW (à partir de laquelle on lance dans la foulée un script de localisation prévu pour récupérer ces identifiants).  
Exemple de script (évidemment à adapter localement) : [*localiser*](https://github.com/oliviercrouzet/catlocsudoc/tree/localiser).  
Ce script est à coller dans le fichier winibw.vbs :   "C:\oclcpica\WinIBW30\Profiles\prenom.nom\winibw.vbs".  
Puis créer un raccourci dans la barre d'outils de Winnie.

