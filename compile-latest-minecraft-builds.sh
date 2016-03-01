Build="/home/Build"
Web="/var/www/html"
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

# MCPro
yes | cp -rf ${Build}/spigot-*.jar ${Web}/mcpro/Spigot/Spigot.jar
yes | cp -rf ${Build}/spigot-1.8*.jar ${Web}/mcpro/Spigot/Spigot188.jar
yes | cp -rf ${Build}/craftbukkit-1*.jar ${Web}/mcpro/CraftBukkit/CraftBukkit.jar
yes | cp -rf ${Build}/craftbukkit-1.8*.jar ${Web}/mcpro/CraftBukkit/CraftBukkit188.jar

# CraftBukkit
yes | cp -rf ${Build}/craftbukkit-1*.jar ${Web}/release/CraftBukkit/
yes | cp -rf ${Build}/craftbukkit-1.9*.jar ${Web}/CraftBukkit.jar

# MCPro
yes | cp -rf ${Build}/spigot-*.jar ${Web}/mcpro/Spigot/Spigot.jar
yes | cp -rf ${Build}/spigot-1.9*.jar ${Web}/mcpro/Spigot/Spigot19.jar
yes | cp -rf ${Build}/craftbukkit-1*.jar ${Web}/mcpro/CraftBukkit/CraftBukkit.jar
yes | cp -rf ${Build}/craftbukkit-1.9*.jar ${Web}/mcpro/CraftBukkit/CraftBukkit19.jar

# Sync
aws s3 sync /var/www/html/mcpro s3://MCProHosting-Misc/

# Cleanup
rm -rf "${Build}"