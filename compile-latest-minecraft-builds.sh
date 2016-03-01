# Compiler for CraftBukkit, Spigot and PaperSpigot
Build="/home/Build"
Web="/var/www/html"
AWS="Downloads"
mkdir ${Build}
cd ${Build}
wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar -O BuildTools.jar

# Stable Build
java -jar BuildTools.jar
# Beta Build
java -jar BuildTools.jar --rev 1.9

# Spigot
yes | cp -rf ${Build}/spigot-*.jar ${Web}/release/Spigot/
yes | cp -rf ${Build}/spigot-1.8*.jar ${Web}/Spigot.jar

# CraftBukkit
yes | cp -rf ${Build}/craftbukkit-1*.jar ${Web}/release/CraftBukkit/
yes | cp -rf ${Build}/craftbukkit-1.8*.jar ${Web}/CraftBukkit.jar

# PaperSpigot
PaperSpigot="paperspigot-1.8.8.jar"
wget https://ci.destroystokyo.com/job/PaperSpigot/lastSuccessfulBuild/artifact/Paperclip.jar -O ${PaperSpigot}
yes | cp -rf ${PaperSpigot} ${Web}/release/PaperSpigot/
yes | cp -rf ${PaperSpigot} ${Web}/PaperSpigot.jar

# Sync
aws s3 sync /var/www/html/*.jar s3://${AWS}/

# Cleanup
rm -rf "${Build}"