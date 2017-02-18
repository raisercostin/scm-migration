#!/bin/bash

function help(){
	cat <<EOL
	prereq: sudo apt-get -y install subversion git-svn
	based on the info from http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/
EOL
}

#call it with: assert "-e file1.txt" File doesn't exist so error!!!!
function assert(){
	if [ $1 ]; then
		#nothing. ignore
		:
	else
		echo "${@:2} . Test [$1] failed."
		exit 1
	fi
}

function prepare(){
	echo "compile a btter svndumpsanitizer tool from https://github.com/dsuni/svndumpsanitizer"
	gcc svndumpsanitizer.c -o svndumpsanitizer
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
	if [ -f $svnProjectName-filtered.svndump ]; then
		echo "[$project] scmFilter> Out file [$svnProjectName-filtered.svndump] already exists."
	else
		(
			cd $project
			echo "filter [$project] with svnProjectSubPath:[$srcSvnProjectSubPath] from: [$svnProjectName.svndump] to: [$svnProjectName-filtered.svndump]"
			#svndumpfilter --drop-empty-revs --renumber-revs include $srcSvnProjectSubPath <$svnProjectName.svndump >$svnProjectName-filtered.svndump
			.././svndumpsanitizer --infile $svnProjectName.svndump --outfile $svnProjectName-filtered.svndump --include $srcSvnProjectSubPath --drop-empty --add-delete --redefine-root $srcSvnProjectSubPath
		)
	fi
}

function scmNewFilteredSvnClean(){
    local project newSvnProjectName
    project="$1"
    newSvnProjectName=$project-svn-filtered	
	rm -rf $project/$newSvnProjectName
}

function scmNewFilteredSvn(){
    local project newSvnProjectName
    project="$1"
    newSvnProjectName=$project-svn-filtered
    svnProjectName=$project-svn

    echo "[$project]$FUNCNAME> Create new filtered svn repo at [$newSvnProjectName]"
	(
		cd $project
		assert "-n -e $newSvnProjectName" "Out file [$newSvnProjectName] already exists."

		echo "info at http://jmsliu.com/2700/more-project-from-one-svn-repository-to-another-one.html"
		#svnProjectPathFiltered=file://`pwd`/$newSvnProjectName
		svnadmin create $newSvnProjectName
		svn info $newSvnProjectName
		svnadmin load $newSvnProjectName < $svnProjectName-filtered.svndump
	)
}

function scmListAuthors(){
    local project newSvnProjectName svnRepo svnProjectName
    project="$1"
    newSvnProjectName=$project-svn-filtered
    svnProjectName=$project-svn
	svnRepo=file://`pwd`/$project/$project-svn-filtered

    echo "[$project]$FUNCNAME> Extract authors from [$newSvnProjectName] and look them up in [authors-all.txt] (if exits)"
	(
		cd $project
		echo "#Users found for [$svnRepo] and lookedup in [authors-all.txt]" > authors.txt
		svn log $svnRepo | scmExtractAuthors >> authors.txt
		cat authors.txt
	)
}


# you can extract authors with:
# . ./migrate.sh && svn log svn://raisercostin2.synology.me/all/projects/namek | scmExtractAuthors
function scmExtractAuthors(){
	#inspired from here http://stackoverflow.com/questions/37488797/how-to-perform-a-key-field-lookup-in-a-file-using-bash-or-awk
	grep '|' | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' - | awk 'NF' | sort -u | awk 'BEGIN{FS=" = ";OFS=","}NR==FNR{email[$1]=$2}NR>FNR{if (email[$1]) print $1" = "email[$1]; else print $1" = "$1"<"$1">";}' <( cat authors-all.txt 2> /dev/null || echo "" ) -
}

function scmGitClone(){
    local project newSvnProjectName svnRepo svnProjectName
    project=${1:?Project name is missing}
	srcSvnProjectSubPath=${2:?Project svn subpath is missing}
    newSvnProjectName=$project-svn-filtered
    svnProjectName=$project-svn
	svnRepo=file://`pwd`/$project/$project-svn-filtered

    echo "[$project]$FUNCNAME> Clone [$svnRepo] with authors from [$project/authors.txt] into [$project.git]"
	(
		cd $project
		git svn clone $svnRepo$srcSvnProjectSubPath --prefix=origin/ --no-metadata --authors-file=authors.txt --tags=tags --branches=branches --trunk=trunk $project.git
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
	scmNewFilteredSvn $project
	scmListAuthors $project
	scmGitClone $project $srcSvnProjectSubPath

    (
		#cd $project
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
