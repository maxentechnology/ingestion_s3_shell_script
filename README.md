L'objectif de ce repository est de permettre l'ingestion programmée et fréquente de données Navada, stockées dans une base SQL, vers un bucket S3 de Maxen. Cette opération facilite le traitement et le nettoyage des données, les rendant ainsi visualisables sur Tableau. Plusieurs fichiers se trouvent dans ce repository, qui sera installé tel quel sur l'ordinateur distant du client :

1. **Script PowerShell : script_query.ps1**
    - Ce script peut être exécuté via Windows PowerShell. Il se charge de requêter la table PostgreSQL et d'envoyer uniquement les dernières données mises à jour, non requêtées dans le passé.

2. **AWSCLI2.zip**
    - Il s'agit d'une version compressée du module AWS CLI. Une fois décompressé, il permet d'exécuter notre script_query.ps1 et d'utiliser la commande aws sans avoir besoin de l'installer en tant qu'administrateur sur l'ordinateur du client. L'installation directe de ce dossier évite d'éventuels problèmes liés à l'accès en tant qu'administrateur, situation qui peut se produire via RDP lorsque le client ne donne pas accès à son ordinateur en tant qu'administrateur.

3. **credentials.txt**
    - Contient le mot de passe du compte de service AWS. À terme, l'idée est de le chiffrer, évitant ainsi la possibilité de le lire en l'ouvrant tout en restant lisible par PowerShell.

4. **date_extract.txt**
    - Permet de conserver en mémoire la dernière date requêtée, assurant ainsi la récupération uniquement des dernières valeurs lors de l'extraction quotidienne ou à une fréquence décidée.

### 1. Connexion à RDP avec VPN sur l'ordinateur distant

### 2. Décompression du dossier AWS CLI :
```powershell
# Dézipper le dossier .zip et le placer dans le dossier Data_Ingestion
Expand-Archive -Path "~\Downloads\AWSCLIV2.zip" -DestinationPath "~\Desktop\Data_Ingestion" -Force
```

### 3. Ouvrir Windows PowerShell et accéder au répertoire du script :
```powershell
# Accéder au répertoire du script sur le bureau
cd ~\Desktop\Data_Ingestion
```

### 4. Mettre à jour la variable d'environnement Path pour utiliser la commande aws :
```powershell
# Ajouter le chemin d'accès à AWS CLI dans la variable d'environnement Path
$env:Path += ";C:\Users\ext_Maxen\Desktop\Data_Ingestion\AWSCLIV2"
```
Cette dernière est aussi disponible au script principal, à savoir script_query.ps1, au cas où.

### 5. Vérifier l'installation d'AWS CLI :
```powershell
# Vérifier l'installation d'AWS CLI
aws --version
```

### 7. Lancer le second script (script_query.ps1) :
```powershell
# Lancer le script de requête
.\script_query.ps1
```

Le script devrait afficher les messages suivants :
```powershell
AWSPowerShell module is already installed 
AWS CLI is installed. Continuing with the rest of the script...
```

Le script_query.ps1 vérifiera les informations de connexion à PostgreSQL et exécutera le reste du code d'extraction. Vous pouvez également ajuster la date de début en modifiant le fichier date_extract.  

### 8. Configurer une tâche planifiée pour exécuter le script quotidiennement :
```powershell
# Créer une tâche planifiée se nommant ScriptTaskScheduled pour exécuter le script tous les jours à 7:00 am

schtasks /create /tn "ScriptTaskScheduled" /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Users\ext_Maxen\Desktop\Data_Ingestion\script_query.ps1" /sc daily /st 07:00
```
Vous pouvez également utiliser `/sc once` pour exécuter la tâche une seule fois ce qui équivaut à `.\script_query.ps1`.

