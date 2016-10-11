#!/bin/bash

#prereq: sudo apt-get -y install subversion git-svn
echo "based on the info from http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/"

function migrateProject(){
    local project srcProjectUrl destProjectUrl shouldPush
    project="$1"
    srcProjectUrl="$2"
    destProjectUrl="$3"
    shouldPush="${4:-false}"
    
    echo "migrate $project [$srcProjectUrl] => [$destProjectUrl]"

    mkdir $project
    (
        cd $project
        svnProjectName=$project-svn
        svnProjectPath=file://`pwd`/$svnProjectName

        svnadmin create $svnProjectName
        echo '#!/bin/sh' > $svnProjectName/hooks/pre-revprop-change
        chmod +x $svnProjectName/hooks/pre-revprop-change
        svnsync init $svnProjectPath $srcProjectUrl
        svnsync sync $svnProjectPath
        svnadmin dump $svnProjectName > $svnProjectName.dump

        #choose one of the following
        #svndumpfilter --drop-empty-revs --renumber-revs exclude trunk/www < $project.dump > $project.filtered.dump
        cp $svnProjectName.dump $svnProjectName-filtered.dump
        mv $svnProjectName $svnProjectName.todel


        svnProjectNameFiltered=$svnProjectName-filtered
        svnProjectPathFiltered=file://`pwd`/$svnProjectNameFiltered
        svnadmin create $svnProjectNameFiltered
        svn info $svnProjectNameFiltered
        svnadmin load $svnProjectNameFiltered < $svnProjectName-filtered.dump

        #list authors
        #svn checkout $svnProjectPath $project-2
        #svn log $project-2 --quiet
        #edit authors.txt
        #git svn clone $svnProjectPath --no-metadata -A authors.txt -t tags -b branches -T trunk $project-git


	git svn clone $svnProjectPathFiltered --prefix=origin/ --no-metadata --tags=tags --branches=branches --trunk=trunk $project.git

        cd $project.git
        git remote add origin $destProjectUrl
        
        if [ "$shouldPush" == 'true' ]; then
            git push --set-upstream origin master
        fi
    )
}

#migrateProject mucommander https://svn.mucommander.com/mucommander/ https://github.com/raisercostin/mucommander.git
migrateProject uumds-repo https://webgate.ec.europa.eu/CITnet/svn/UUMDS https://github.com/raisercostin/uumds/uumds-repo.git

