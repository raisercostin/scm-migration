#!/bin/bash

echo "based on the info from http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/"
svnUrl=https://svn.mucommander.com/mucommander/
project=mucommander


projectPath=file://`pwd`/$project
currentName=$project
scmProject=$svnUrl
svnadmin create $project
echo '#!/bin/sh' > $project/hooks/pre-revprop-change
chmod +x $project/hooks/pre-revprop-change
svnsync init $projectPath $scmProject
svnsync sync $projectPath
svnadmin dump $currentName > $project.dump

#choose one of the following
#svndumpfilter --drop-empty-revs --renumber-revs exclude trunk/www < $project.dump > $project.filtered.dump
cp $project.dump $project.filtered.dump

mv $project $project.dumped.todel
svnadmin create $project
svnadmin load $project < $project.filtered.dump

#list authors
#svn checkout $projectPath $project-2
#svn log $project-2 --quiet
#edit authors.txt
#git svn clone $projectPath --no-metadata -A authors.txt -t tags -b branches -T trunk $project-git


git svn clone $projectPath --no-metadata -t tags -b branches -T trunk $project.git
cd $project.git
git remote add origin https://github.com/raisercostin/$project.git
