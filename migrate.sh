#!/bin/bash

help=$( cat <<EOF_USAGE
\tprereq: sudo apt-get -y install subversion git-svn
\tbased on the info from http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/
EOF_USAGE
)


internal_yell() { echo "$*" >&2; }
yell() { internal_yell "$0>${FUNCNAME[1]}: $*"; }
die() { internal_yell "$0>${FUNCNAME[1]}: $*"; exit 111; }
try() { "$@" || internal_yell "cannot $*"; }

#call it with: assert "-e file1.txt" File doesn't exist so error!!!!
function assert(){
	if [ $1 ]; then
		#nothing. ignore
		:
	else
		echo "${@:2} . Test [$1] failed." >&2
		exit 1
	fi
}

function prepare(){
	echo "compile a btter svndumpsanitizer tool from https://github.com/dsuni/svndumpsanitizer" >&2
	gcc svndumpsanitizer.c -o svndumpsanitizer
}

function scmSvnClone(){
    local srcProjectUrl destProjectSvn
    srcProjectUrl="$1"
    destProjectSvn="$2"
    
    echo "migrate $project [$srcProjectUrl] => [$destProjectSvn]" >&2

	svnProjectPath=file://`pwd`/$destProjectSvn

	svnadmin create $destProjectSvn
	echo '#!/bin/sh' > $destProjectSvn/hooks/pre-revprop-change
	chmod +x $destProjectSvn/hooks/pre-revprop-change
	svnsync init $svnProjectPath $srcProjectUrl
	svnsync sync $svnProjectPath
    svnadmin dump $destProjectSvn > $destProjectSvnDump
}

function scmSvnDump(){
    svnadmin dump $1 > $2
}

function scmFilter(){
    local src dest srcSvnProjectSubPath
    src="$1"
    dest="$2"
    redefinedRoot="$3"
    srcSvnProjectSubPath="${@:4}"

	if [ -f $dest ]; then
		yell Dest file [$dest] already exists.
	else
		yell Filter from [$src] to [$dest] with svnProjectSubPath [$srcSvnProjectSubPath]
		#svndumpfilter --drop-empty-revs --renumber-revs include $srcSvnProjectSubPath <$svnProjectName.svndump >$svnProjectName-filtered.svndump
		#.././svndumpsanitizer --infile $src-svn.svndump --outfile $dest --include $srcSvnProjectSubPath --drop-empty --add-delete --redefine-root $srcSvnProjectSubPath
		./svndumpsanitizer --infile $src --outfile $dest --include $srcSvnProjectSubPath --drop-empty --add-delete --redefine-root $redefinedRoot
	fi
}

function scmSvnFilteredClone(){
    local src dest
    src="$1"
    dest="$2"
	[[ ! -d $dest ]] || die Out folder [$dest] already exists.

    yell Create new filtered svn repo at [$dest]
	(
		yell info at http://jmsliu.com/2700/more-project-from-one-svn-repository-to-another-one.html
		svnadmin create $dest
		svn info $dest
		svnadmin load $dest < $src
	)
}

function scmListAuthors(){
    local src dest inAuthors svnRepo
    src="$1"
    dest="${2:-authors.txt}"
    inAuthors="${3:-authors-all.txt}"
	svnRepo=file://`pwd`/$src

    echo "[$src]$FUNCNAME> Extract authors from [$src] and look them up in [$inAuthors] (if exits)" >&2
	echo "#Users found for [$svnRepo] and lookedup in [$inAuthors]" >$dest
	svn log $svnRepo | scmExtractAuthors $inAuthors >> $dest
	cat $dest
}


# you can extract authors with:
# . ./migrate.sh && svn log svn://raisercostin2.synology.me/all/projects/namek | scmExtractAuthors
function scmExtractAuthors(){
	local inAuthors
    inAuthors="${1:-authors-all.txt}"
	#inspired from here http://stackoverflow.com/questions/37488797/how-to-perform-a-key-field-lookup-in-a-file-using-bash-or-awk
	grep '|' | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' - | awk 'NF' | sort -u | awk 'BEGIN{FS=" = ";OFS=","}NR==FNR{email[$1]=$2}NR>FNR{if (email[$1]) print $1" = "email[$1]; else print $1" = "$1"<"$1">";}' <( cat $inAuthors 2> /dev/null || echo "" ) -
}

function scmGitClone(){
    local project newSvnProjectName svnRepo svnProjectName
    project=${1:?Project name is missing}
	srcSvnProjectSubPath=${2:?Project svn subpath is missing}
    newSvnProjectName=$project
    svnProjectName=$project-svn
	svnRepo=file://`pwd`/$project/$project

    echo "[$project]$FUNCNAME> Clone [$svnRepo] with authors from [$project/authors.txt] into [$project.git]" >&2
	(
		cd $project
		git svn clone $svnRepo$srcSvnProjectSubPath --prefix=origin/ --authors-file=authors.txt --stdlayout $project.git #--tags=tags --branches=branches --trunk=trunk $project.git
		(
			cd $project.git
			echo "- Converting svn:ignore properties into a .gitignore file..." >&2
			git svn show-ignore --id trunk >> .gitignore
			git add .gitignore
			git commit --author="git-svn-migrate <nobody@example.org>" -m 'Convert svn:ignore properties to .gitignore.'
			
			
			echo "Rename Subversion's [trunk] branch to Git's standard [master] branch." >&2
			cd $destination/$name.git;
			git branch -m trunk master

			# Remove bogus branches of the form "name@REV".
#			git for-each-ref --format='%(refname)' refs/heads | grep '@[0-9][0-9]*' | cut -d / -f 3- | xargs -L1 git branch -D "$ref";
#			while read ref
#			do
#				git branch -D "$ref";
#			done

			# Convert git-svn tag branches to proper tags.
#			echo "- Converting svn tag directories to proper git tags..." >&2;
#			git for-each-ref --format='%(refname)' refs/heads/tags | cut -d / -f 4 |
#			while read ref
#			do
#				git tag -a "$ref" -m "Convert \"$ref\" to a proper git tag." "refs/heads/tags/$ref";
#				git branch -D "tags/$ref";
#			done
		)
	)
}

function scmGitClone2(){
	line=${@:1}

	# Check for 2-field format:  Name [tab] URL
	name=`echo $line | awk '{print $1}'`;
	url=`echo $line | awk '{print $2}'`;
	# Check for simple 1-field format:  URL
	if [[ $url == '' ]]; then
	url=$name;
	name=`basename $url`;
	fi
	scmGitClone3 $name authors.txt $url $name.git
}

function scmGitClone3(){
	local name authors url dest
	name=${1:?srcSvnUrl is missing}
	authors=${2:?authors file is missing}
	dest=${3:?Destination is missing}
	redefinedRoot=${4:?project root is missing}

	url=file://`pwd`/$name/namek
	scmGitClone4 $name $authors $url $dest $redefinedRoot
}
function scmGitClone4(){
	local name authors url dest
	(
		name=${1:?srcSvnUrl is missing}
		authors=${2:?authors file is missing}
		url=${3:?srcSvnUrl is missing}
		dest=${4:?Destination is missing}

		# Process each Subversion URL.
		echo >&2;
		echo "At $(date)..." >&2;
		echo "Processing \"$name\" repository at $url..." >&2;

		#mkdir $name
		#cd $name
		tmp_destination="$name-tmp.git";
		destination=$dest
		gitinit_params=""
		gitsvn_params=""
		

		(
			echo "Init the final bare repository at $destination" <&2
			mkdir -p $destination
			cd $destination
			git init --bare $gitinit_params
		)

		# Clone the original Subversion repository to a temp repository.
		(
			mkdir -p $tmp_destination
			echo "- Cloning repository..." >&2;
			#git svn clone $url --prefix=origin/ --authors-file=../namek/authors.txt --stdlayout --quiet $gitsvn_params $tmp_destination;
			echo git svn clone $url --prefix=svn/ --authors-file=$authors --stdlayout $gitsvn_params $tmp_destination;
			git svn clone $url --prefix=svn/ --authors-file=$authors --stdlayout $gitsvn_params $tmp_destination;

			# Create .gitignore file.
			echo "- Converting svn:ignore properties into a .gitignore file..." >&2;
			if [[ $ignore_file != '' ]]; then
				cp $ignore_file $tmp_destination/.gitignore;
			fi
			(
				cd $tmp_destination;
				git svn show-ignore --id trunk >> .gitignore;
				git add .gitignore;
				git commit --author="git-svn-migrate <nobody@example.org>" -m 'Convert svn:ignore properties to .gitignore.';

				# Push to final bare repository and remove temp repository.
				echo "- Pushing to new bare repository..." >&2
				git remote add bare ../$destination
				git config remote.bare.push 'refs/remotes/*:refs/heads/*'
				git push bare;
				# Push the .gitignore commit that resides on master.
				#git push bare master:trunk;
			)
		)
		rm -rf $tmp_destination;

		(
			# Rename Subversion's "trunk" branch to Git's standard "master" branch.
			cd $destination
			git branch -m svn/trunk master
			git symbolic-ref HEAD refs/heads/master

			# Remove bogus branches of the form "name@REV".
			#git for-each-ref --format='%(refname)' refs/heads | grep '@[0-9][0-9]*' | cut -d / -f 3- |
			#while read ref
			#do
			#git branch -D "$ref";
			#done

			#TODO replace while read with xargs?
			# Convert git-svn tag branches to proper tags.
echo "- Converting svn tag directories to proper git tags..." >&2;
git for-each-ref --format='%(refname)' refs/heads/svn/tags | cut -d / -f 5 |
while read ref
do
git tag -a "$ref-svn" -m "Original svn \"$ref\" tag." "refs/heads/svn/tags/$ref"
git tag -a "$ref" -m "Original svn tag was applied to this commit \"$ref\" to a proper git tag." "refs/heads/svn/tags/$ref~1";
git branch -D "svn/tags/$ref";
#delte remote??
#git push origin ":refs/heads/origin/tags/$ref"
#git push origin tag "$ref"
done

  
			#git config receive.denyCurrentBranch updateInstead
			#git checkout master

			echo "Show all references:" >&2
			git show-ref
			echo "Current branches:" >&2
			git branch -a
			echo "Current tags:" >&2
			git tag -l
		)
		echo "- Conversion completed at $(date)." >&2;
  )
}

function explain(){
	local srcSvnUrl dest
	srcSvnUrl="$1"
    dest="$2"
	echo "You could execute the followings"
	echo "------------------"
	echo scmSvnClone $srcSvnUrl $dest-1.svn
	echo scmSvnDump $dest-1.svn $dest-2.svndump
	echo scmFilter $dest-2.svndump $dest-3.filtered-svndump projects projects/namek projects/darzar
	echo scmSvnFilteredClone $dest-3.filtered-svndump $dest-4.svn
	echo scmListAuthors $dest-4.svn $dest-5-authors.txt
	echo scmGitClone3 $dest-4.svn $dest-5-authors.txt $dest-6.git /namek
}

#. ./migrate.sh && (migrateProject svn://raisercostin2.synology.me/all/projects/namek namek2)
function migrateProject(){
	srcSvnUrl="$1"
    dest="$2"
    #srcProjectUrl="$2"
    #destProjectUrl="$3"
    #srcSvnProjectSubPath="$4"
    #shouldPush="${5:-false}"
    #echo "migrate $dest [$srcProjectUrl] => [$destProjectUrl]"
	
	scmSvnClone $srcSvnUrl $dest-1.svn
	scmSvnDump $dest-1.svn $dest-2.svndump
	scmFilter $dest-2.svndump $dest-3.filtered-svndump projects projects/namek projects/darzar
	scmSvnFilteredClone $dest-3.filtered-svndump $dest-4.svn
	scmListAuthors $dest-4.svn $dest-5-authors.txt
	scmGitClone3 $dest-4.svn $dest-5-authors.txt $dest-6.git /namek

	yell "To clean run [ rm -rf $dest-1.svn $dest-2.svndump $dest-3.filtered-svndump $dest4.svn $dest-4-authors.txt"
		#cd $project
        #cd $project.git
        #git remote add origin $destProjectUrl
        
        #if [ "$shouldPush" == 'true' ]; then
        #    git push --set-upstream origin master
        #fi
		:
}
#execute with 
# . ./migrate.sh && scmFilter namek /projects/namek

#migrateProject mucommander https://svn.mucommander.com/mucommander/ https://github.com/raisercostin/mucommander.git
#migrateProject namek svn://raisercostin2.synology.me/all/projects/namek projects/namek
#scmImport namek svn://raisercostin2.synology.me/all/projects/namek
#scmFilter namek /projects/namek
#scmNewFilteredSvn namek
