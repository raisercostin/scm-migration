#!/bin/bash

function help(){
	cat <<EOL
	prereq: sudo apt-get -y install subversion git-svn
	based on the info from http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/
EOL
}

function scmImport(){
    local project srcProjectUrl
    project="$1"
    srcProjectUrl="$2"
    
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
        svnadmin dump $svnProjectName > $svnProjectName.svndump
	)
}

function scmFilter(){
    local project srcProjectUrl svnProjectName
    project="$1"
    srcSvnProjectSubPath="$2"
    svnProjectName=$project-svn

    (
        cd $project
		echo "filter [$project] with svnProjectSubPath:[$srcSvnProjectSubPath] from: [$svnProjectName.svndump] to: [$svnProjectName-filtered.svndump]"
		svndumpfilter --drop-empty-revs --renumber-revs include $srcSvnProjectSubPath <$svnProjectName.svndump >$svnProjectName-filtered.svndump
	)
}

function scmNewFilteredSvn(){
    local project newSvnProjectName
    project="$1"
    newSvnProjectName=$project-svn-filtered
    svnProjectName=$project-svn

    echo "[$project]> Create new filtered svn repo at [$newSvnProjectName]"

    (
		cd $project
        #svnProjectPathFiltered=file://`pwd`/$newSvnProjectName
        svnadmin create $newSvnProjectName
        svn info $newSvnProjectName
        svnadmin load $newSvnProjectName < $svnProjectName-filtered.svndump
	)
}


function migrateProject(){
    local project srcProjectUrl destProjectUrl shouldPush
    project="$1"
    srcProjectUrl="$2"
    destProjectUrl="$3"
    srcSvnProjectSubPath="$4"
    shouldPush="${5:-false}"
    
    echo "migrate $project [$srcProjectUrl] => [$destProjectUrl]"
	
	scmImport $project $srcProjectUrl
	scmFilter $project $srcSvnProjectSubPath

    mkdir $project
    (
        cd $project

        #choose one of the following
        #svndumpfilter --drop-empty-revs --renumber-revs exclude trunk/www < $project.dump > $project.filtered.dump
		#svndumpfilter --drop-empty-revs --renumber-revs include projects/namek < $project.dump > $project.filtered.dump
        #cp $svnProjectName.dump $svnProjectName-filtered.dump
        #mv $svnProjectName $svnProjectName.todel


        #svnProjectNameFiltered=$svnProjectName-filtered
        #svnProjectPathFiltered=file://`pwd`/$svnProjectNameFiltered
        #svnadmin create $svnProjectNameFiltered
        #svn info $svnProjectNameFiltered
        #svnadmin load $svnProjectNameFiltered < $svnProjectName-filtered.dump

        #list authors
        #svn checkout $svnProjectPath $project-2
        #svn log $project-2 --quiet
        #edit authors.txt
        #git svn clone $svnProjectPath --no-metadata -A authors.txt -t tags -b branches -T trunk $project-git


	#git svn clone $svnProjectPathFiltered --prefix=origin/ --no-metadata --tags=tags --branches=branches --trunk=trunk $project.git

        #cd $project.git
        #git remote add origin $destProjectUrl
        
        #if [ "$shouldPush" == 'true' ]; then
        #    git push --set-upstream origin master
        #fi
    )
}
#execute with 
# . ./migrate.sh && scmFilter namek /projects/namek

#migrateProject mucommander https://svn.mucommander.com/mucommander/ https://github.com/raisercostin/mucommander.git
#migrateProject namek svn://raisercostin2.synology.me/all/projects/namek projects/namek
#scmImport namek svn://raisercostin2.synology.me/all/projects/namek
#scmFilter namek /projects/namek
#scmNewFilteredSvn namek