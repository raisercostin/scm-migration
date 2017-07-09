#!/bin/bash

#some utilities
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

function scmInit(){
	sudo apt-get -y install subversion git-svn
	echo "compile a btter svndumpsanitizer tool from https://github.com/dsuni/svndumpsanitizer" >&2
	gcc svndumpsanitizer.c -o svndumpsanitizer
}


function scmHelp(){
	echo "
$( cat <<-EOF_USAGE
	---------------------------------------------------------------------------------------------------------
	scmExplain  - prints a suggested plan for migration for your repository. Highly recommended.
	              Try:
	                   scmExplain https://svn.mucommander.com/mucommander mu
	
	scmRemoteSvnExport - **executes** the entire scmExplain migration plan for a full remote svn repo
	scmExport         - **executes** the entire scmExplain migration plan for a full locally cloned svn repo
	scmFilteredExport - **executes** the entire scmExplain migration plan for a filtered svn repo
	
	scmSvnClone       - clonses locally a remote svn repo
	scmSvnDump        - dumps a local svn clone to a file using svndumpsanitizer
	scmSvnDumpFilter  - filters an svn dump
	scmSvnFilteredClone - clonses locally a svn repo from an svndump
	scmListAuthors    - lists authors from a local svn
	scmGitClone       - clones in git from a local svn using provided authors

	scmHelp           - this help
	scmInit           - installs prerequisites: svn, git, git-svn, svndumpsanitizer

	These are the functions defined by the script.
	If you executed it with '. ./scm.sh' you will be able to call them directly like for example '$ scmHelp'

	Samples:
	    scmExplain https://svn.mucommander.com/mucommander mu
	    scmExplain https://svn.java.net/svn/yanfs~svn yanfs
	    scmExplain svn://raisercostin2.synology.me/all/projects/namek namek
		scmExplain http://svn.code.sf.net/p/upnplibmobile/code/ upnplibmobile

EOF_USAGE
)
"
}



function scmExplain(){
	local syntax srcSvnUrl dest
	syntax="Syntax: scmExplain <srcSvnUrl> <destPrjName>"
	srcSvnUrl=${1:-https://myserver.com/someProject}
    dest=${2:-myPrj}
	redefinedRoot=${3:-projects}
	includePaths=${4:-projects/namek projects/darzar}
	prjRootWhereTrunkTagsBranchesExists=${4:-/namek}
	echo "
$( cat <<-EOF_USAGE
	---------------------------------------------------------------------------------------------------------
	
	A) Clone from a remote svn

	    scmRemoteSvnExport $srcSvnUrl $dest

	    will execute the following:
	        scmListAuthors $srcSvnUrl > $dest-5-authors.txt
	        scmGitClone $srcSvnUrl / $dest-5-authors.txt $dest-6.git



	B) Clone from a full local svn (faster than from a remote svn?)

	    scmExport $srcSvnUrl $dest
	
	    will execute the following:
	        scmSvnClone $srcSvnUrl $dest-1.svn
	        scmListAuthors $dest-1.svn > $dest-5-authors.txt
	        scmGitClone $dest-1.svn / $dest-5-authors.txt $dest-6.git

	
	
	C) Clone from a filtered local svn (filtering can happen only localy)
	
	    scmFilterdExport $srcSvnUrl $prjRootWhereTrunkTagsBranchesExists $dest projects projects/namek projects/darzar

	    will execute the following:
	
	        scmSvnClone $srcSvnUrl $dest-1.svn
	        scmSvnDump $dest-1.svn $dest-2.svndump
	        scmSvnDumpFilter $dest-2.svndump $dest-3.filtered-svndump $redefinedRoot $includePaths
	        scmSvnFilteredClone $dest-3.filtered-svndump $dest-4.svn
	        scmListAuthors $dest-4.svn > $dest-5-authors.txt
	        scmGitClone $dest-4.svn $prjRootWhereTrunkTagsBranchesExists $dest-5-authors.txt $dest-6.git

EOF_USAGE
)
"
	: ${1:?$syntax}
	: ${2:?$syntax}
}


function scmRemoteSvnExport(){
	local syntax srcSvnUrl dest
	syntax="Syntax: scmRemoteSvnExport <srcSvnUrl> <destPrjName>"
	srcSvnUrl=${1:?$syntax}
	dest=${2:?$syntax}
	yell "executing> scmExport [$srcSvnUrl] [$dest]"
	
	scmListAuthors $srcSvnUrl > $dest-5-authors.txt
	scmGitClone $srcSvnUrl / $dest-5-authors.txt $dest-6.git

	yell "!!! To clean run [ rm -rf $dest-1.svn $dest-5-authors.txt ]"
}

function scmExport(){
	local syntax srcSvnUrl dest
	syntax="Syntax: scmExport <srcSvnUrl> <destPrjName>"
	srcSvnUrl=${1:?$syntax}
	dest=${2:?$syntax}
	yell "executing> scmExport [$srcSvnUrl] [$dest]"
	
	scmSvnClone $srcSvnUrl $dest-1.svn
	scmListAuthors $dest-1.svn > $dest-5-authors.txt
	scmGitClone $dest-1.svn / $dest-5-authors.txt $dest-6.git

	yell "!!! To clean run [ rm -rf $dest-1.svn $dest-5-authors.txt ]"
}


function scmFilteredExport(){
	local syntax srcSvnUrl dest redefinedRoot
	syntax="Syntax: scmFilteredExport <srcSvnUrl> <destPrjName> <redefinedRoot> <includePaths> . See './svndumpsanitizer -h' for more details on <redefinedRoot> and <includePaths>"
	srcSvnUrl=${1:?$syntax}
	dest=${2:?$syntax}
	redefinedRoot=${3:?$syntax}
	includePaths=${4:?$syntax}
    yell "executing> scmFilteredExport $srcSvnUrl $dest $redefinedRoot $includePaths"
	
	scmSvnClone $srcSvnUrl $dest-1.svn
	scmSvnDump $dest-1.svn $dest-2.svndump
	scmSvnDumpFilter $dest-2.svndump $dest-3.filtered-svndump $redefinedRoot $includePaths
	scmSvnFilteredClone $dest-3.filtered-svndump $dest-4.svn
	scmListAuthors $dest-4.svn > $dest-5-authors.txt
	scmGitClone $dest-4.svn $dest-5-authors.txt $dest-6.git $redefinedRoot

	yell "To clean run [ rm -rf $dest-1.svn $dest-2.svndump $dest-3.filtered-svndump $dest-4.svn $dest-5-authors.txt"
}


function scmSvnClone(){
    local syntax srcProjectUrl destProjectSvn
	syntax="Syntax: scmSvnClone <srcSvnLocalRepoDir> <destProjectSvn>"
    srcProjectUrl=${1:?Src svn url is missing. Eg. svn://raisercostin2.synology.me/all}
    destProjectSvn=${2:?Destination name of project is missing. Eg. myprj1}
	yell "scmSvnClone $srcProjectUrl $destProjectSvn"

	svnProjectPath=file://`pwd`/$destProjectSvn

	svnadmin create $destProjectSvn
	echo '#!/bin/sh' > $destProjectSvn/hooks/pre-revprop-change
	chmod +x $destProjectSvn/hooks/pre-revprop-change
	svnsync init $svnProjectPath $srcProjectUrl
	svnsync sync $svnProjectPath
}


function scmSvnDump(){
    local syntax srcSvnLocalRepoDir destSvnDumpFile
	syntax="Syntax: scmSvnDump <srcProjectUrl> <destSvnDumpFile>"
	srcProjectUrl=${1:?$syntax}
	destSvnDumpFile=${2:?$syntax}
    yell "scmSvnDump $srcProjectUrl $destSvnDumpFile"
	
    svnadmin dump $srcProjectUrl > $destSvnDumpFile
}


function scmSvnDumpFilter(){
    local syntax src dest redefinedRoot srcSvnProjectSubPath
	syntax="Syntax: scmSvnDumpFilter <srcSvnDumpToFilter> <destSvnDumpFiltered> <> <>"
    src=${1:?$syntax}
    dest=${2:?$syntax}
    redefinedRoot="$3"
    srcSvnProjectSubPath="${@:4}"
	yell "scmSvnDumpFilter $src $dest $redefinedRoot $srcSvnProjectSubPath"

	if [ -f $dest ]; then
		yell "Dest file [$dest] already exists."
	else
		#The svndumpfilter cannot do the job properly since is just a filter: you cannot blindly filter paths since they might be part of the final needed path.
		#svndumpfilter --drop-empty-revs --renumber-revs include $srcSvnProjectSProjectSubPath <$svnProjectName.svndump >$svnProjectName-filtered.svndump
		echo "./svndumpsanitizer --infile $src --outfile $dest --drop-empty --add-delete --redefine-root $redefinedRoot --include $srcSvnProjectSubPath"
		./svndumpsanitizer --infile $src --outfile $dest --drop-empty --add-delete --redefine-root $redefinedRoot --include $srcSvnProjectSubPath 
	fi
}


function scmSvnFilteredClone(){
    local syntax src dest
	syntax="Syntax: scmSvnFilteredClone <src> <dest>"
    src=${1:?$syntax}
    dest=${2:?$syntax}
	yell "scmSvnFilteredClone $src $dest"
	(
		[[ ! -d $dest ]] || die Out folder [$dest] already exists.

		svnadmin create $dest
		svn info $dest
		svnadmin load $dest < $src
	)
}

function scmListAuthors(){
    local syntax src dest inAuthors svnRepo
	syntax="Syntax: scmListAuthors <src> [dest] [inAuthors]"
    src=${1:?$syntax}
    inAuthors=${2:-authors-all.txt}
	if [ -d $src ]; then
		svnRepo=file://`pwd`/$src
	else
		svnRepo=$src
	fi

	echo "#Users found for [$svnRepo] and lookedup in [$inAuthors]"
	svn log $svnRepo | scmExtractAuthors $inAuthors
}


# you can extract authors with:
# . ./migrate.sh && svn log svn://raisercostin2.synology.me/all/projects/namek | scmExtractAuthors
#inspired from here http://stackoverflow.com/questions/37488797/how-to-perform-a-key-field-lookup-in-a-file-using-bash-or-awk
function scmExtractAuthors(){
	local inAuthors
    inAuthors="${1:-authors-all.txt}"
	grep '|' | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2}' - | awk 'NF' | sort -u | awk 'BEGIN{FS=" = ";OFS=","}NR==FNR{email[$1]=$2}NR>FNR{if (email[$1]) print $1" = "email[$1]; else print $1" = "$1"<"$1">";}' <( cat $inAuthors 2> /dev/null || echo "" ) -
}

function scmGitClone(){
	local syntax name authors dest url dest gitInitParams gitSvnParams gitTmpClone
	syntax="Syntax: scmGitClone <name> <prjRootWhereTrunkTagsBranchesExists> <authors> <dest>"
	name=${1:?srcSvnUrl is missing}
	prjRoot=${2:?prjRoot is missing. The prjRoot has the standard structure}
	authors=${3:?authors file is missing}
	dest=${4:?Destination is missing}
	gitInitParams=${5:-}
	gitSvnParams=${6:-}
	yell "scmGitClone $name $prjRoot $authors $dest"
	
	if [ -d $name ]; then
		url=file://`pwd`/$name$prjRoot
	else
		url=$name$prjRoot
	fi
	yell "Svn url is [$url]"

	(
		[[ ! -d $dest ]] || die Out folder [$dest] already exists.
		(
			yell "Init the final bare repository at $dest"
			mkdir -p $dest
			cd $dest
			git init --bare $gitInitParams
		)

		(
			gitTmpClone="$dest-tmp";
			yell "Clone the original Subversion repository to the temp repository $gitTmpClone using authors from 
				$auhtors"
			mkdir -p $gitTmpClone
			echo git svn clone $url --prefix=svn/ --authors-file=$authors --stdlayout $gitSvnParams $gitTmpClone;
			git svn clone $url --prefix=svn/ --authors-file=$authors --stdlayout $gitSvnParams $gitTmpClone;

			yell "Converting svn:ignore properties into a .gitignore file..."
			if [[ $ignore_file != '' ]]; then
				cp $ignore_file $gitTmpClone/.gitignore;
			fi

			(
				cd $gitTmpClone;
				git svn show-ignore --id trunk >> .gitignore
				
				if [ -s .gitignore ]; then
					git add .gitignore
					git commit --author="nobody <nobody>" -m 'Convert svn:ignore properties to .gitignore.'
				fi

				yell "Pushing from $gitTmpClone to $dest"
				git remote add bare ../$dest
				git config remote.bare.push 'refs/remotes/*:refs/heads/*'
				git push bare
				git push bare master:svn/trunk
			)
		)
		yell "now stop"
		#exit 1;

		(
			# Rename Subversion's "trunk" branch to Git's standard "master" branch.
			cd $dest

			yell "Rename svn/trunk to master"
			git branch -m svn/trunk master
			#git symbolic-ref HEAD refs/heads/master

			
			# For now keep them to be removed manually
			# Remove bogus branches of the form "name@REV".
			#git for-each-ref --format='%(refname)' refs/heads | grep '@[0-9][0-9]*' | cut -d / -f 3- |
			#while read ref
			#do
			#git branch -D "$ref";
			#done

			#TODO replace while read with xargs?
			# Convert git-svn tag branches to proper tags.
			yell "Converting svn tag directories to proper git tags..."
			git for-each-ref --format='%(refname)' refs/heads/svn/tags | cut -d / -f 5 |
				while read ref
				do
					git tag -a "$ref-svn" -m "Original svn \"$ref\" tag." "refs/heads/svn/tags/$ref"
					git tag -a "$ref" -m "Original svn tag was applied to this commit \"$ref\" to a proper git tag." "refs/heads/svn/tags/$ref~1";
					git branch -D "svn/tags/$ref";
				done


			#TODO git init as non bare and updateInstead. This will remove the need for a temp for ignore and will create a local checked out git (that can be used to do other things)
			#git config receive.denyCurrentBranch updateInstead
			#git checkout master
			yell "Show all references:"
			git show-ref
			yell "Current branches:"
			git branch -a
			yell "Current tags:"
			git tag -l
		)
	)
	echo "- Conversion completed at $(date)." >&2;
}

scmHelp
