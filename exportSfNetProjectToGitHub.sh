#!/bin/bash

echo "based on the info from http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/"
project=farmanager
projectPath=file://`pwd`/$project
currentName=$project
scmProject=http://svn.code.sf.net/p/$currentName/code/
svnadmin create $project
echo '#!/bin/sh' > $project/hooks/pre-revprop-change
chmod +x $project/hooks/pre-revprop-change
svnsync init $projectPath $scmProject
svnsync sync $projectPath
svnadmin dump yanfs > $project.dump
svndumpfilter --drop-empty-revs --renumber-revs exclude trunk/www < $project.dump > $project.filtered.dump
rm -rf $project
svnadmin create $project
svnadmin load $project < $project.filtered.dump
#list authors
svn checkout $projectPath $project-2
svn log $project-2 --quiet
#edit authors.txt
#git svn clone $projectPath --no-metadata -A authors.txt -t tags -b branches -T trunk $project-git
git svn clone $projectPath --no-metadata -t tags -b branches -T trunk $project.git
cd $project.git
git remote add origin https://github.com/raisercostin/$project.git
