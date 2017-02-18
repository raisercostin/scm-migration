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
    local project newSvnProjectName
    project="$1"
    newSvnProjectName=$project-svn-filtered
    svnProjectName=$project-svn

    #echo "[$project]$FUNCNAME> Extract authors from [$newSvnProjectName]"
	(
		#cd $project
		#assert "-e $newSvnProjectName" "File [$newSvnProjectName] should exist!"

		#svn checkout file://`pwd`/$newSvnProjectName $project-fresh-svn-checkout
		#svn log $project-fresh-svn-checkout --xml | grep /author | sort -u | perl -pe 's/.>(.?)<./$1 = /' > users.txt
		svnRepo=file://`pwd`/$newSvnProjectName
		echo "#Users found for [$svnRepo] and lookedup in [authors-all.txt]" > authors.txt
		#works also on remote url
		#svn log $svnRepo --quiet | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' | sort -u > authors-svn.txt
		#lookup authors in authors-all.txt
		#join -j 1 -o 1.1 2.2 2.3 2.4 <(svn log $svnRepo --quiet | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' | sort -u) <(sort ../authors-all.txt) -a1 -e "unknown"|sed -r 's/^([^ ]*) = unknown unknown/\1 = \1 <\1@unknwon.unknwon>/' >> authors.txt
		
		svn log svn://raisercostin2.synology.me/all/projects/namek | scmExtractAuthors >> authors.txt
		cat authors.txt
	)
}


# you can extract authors with:
# . ./migrate.sh && svn log svn://raisercostin2.synology.me/all/projects/namek | scmExtractAuthors
function scmExtractAuthors(){
	#join -j 1 -o 1.1 2.2 2.3 2.4 <(awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' - | sort -u) <(sort authors-all.txt) -a1 -e "unknown"|sed -r 's/^([^ ]*) = unknown unknown/\1 = \1 <\1@unknwon.unknwon>/'
	#grep '|' | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' - | awk 'NF' | sort -u | join -j 1 -o 1.1 2.2 2.3 2.4 - <(sort authors-all.txt) -a1 -e "unknown"|sed -r 's/^([^ ]*) unknown unknown unknown/\1 = \1 <\1@unknwon.unknwon>/'

	#now there is a bug if authors are similar: raiser and raisercostin
	#maybe improve from here http://stackoverflow.com/questions/37488797/how-to-perform-a-key-field-lookup-in-a-file-using-bash-or-awk
	#awk 'BEGIN{FS=OFS=","}NR==FNR{a[$1]=1;b[$1]=$3;c[$1]=$6;}NR>FNR{if (a[$1]) print $1,b[$1],c[$1]; else print $1,"KEY_NOT_FOUND";}' file2 file1 > file3
	grep '|' | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' - | awk 'NF' | sort -u | awk 'BEGIN{FS=" = ";OFS=","}NR==FNR{email[$1]=$2}NR>FNR{if (email[$1]) print $1" = "email[$1]; else print $1" = "$1"<"$1"@unknown.unk>";}' authors-all.txt -
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
