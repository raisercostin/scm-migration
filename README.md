# Issues

- If you have in svn history a `rename` stored as a `delete` and `add` git will not detect the history passing that point.

# Usage

## Windows 10 with Ubuntu

Install git
```
sudo apt-get install subversion
sudo apt-get install git-svn
. scm.sh
scmExplain  https://svn.code.sf.net/p/javaocr/code
```

## linux

1. Initialize export functions

	. ./scm.sh
	
2. Check what options you have with scmExplain

	scmExplain https://svn.mucommander.com/mucommander mu

3. Execute some of the suggested scripts (printed by scmExplain)

	---------------------------------------------------------------------------------------------------------

	A) Clone from a remote svn

		scmRemoteSvnExport https://svn.mucommander.com/mucommander mu

		will execute the following:
			scmListAuthors https://svn.mucommander.com/mucommander > mu-5-authors.txt
			scmGitClone https://svn.mucommander.com/mucommander / mu-5-authors.txt mu-6.git



	B) Clone from a full local svn (faster than from a remote svn?)

		scmExport https://svn.mucommander.com/mucommander mu

		will execute the following:
			scmSvnClone https://svn.mucommander.com/mucommander mu-1.svn
			scmListAuthors mu-1.svn > mu-5-authors.txt
			scmGitClone mu-1.svn / mu-5-authors.txt mu-6.git



	C) Clone from a filtered local svn (filtering can happen only localy)

		scmFilteredExport <srcSvnUrl> <destPrjName> <commonPathOfAllIncludes> <includePath1> ... <includePathN>
		scmFilterdExport https://svn.mucommander.com/mucommander /namek mu projects projects/namek projects/darzar

		will execute the following:

			scmSvnClone https://svn.mucommander.com/mucommander mu-1.svn
			scmSvnDump mu-1.svn mu-2.svndump
			scmSvnDumpFilter mu-2.svndump mu-3.filtered-svndump projects projects/namek projects/darzar
			scmSvnFilteredClone mu-3.filtered-svndump mu-4.svn
			scmListAuthors mu-4.svn > mu-5-authors.txt
			scmGitClone mu-4.svn /namek mu-5-authors.txt mu-6.git


1. Extract authors

	If the script finds a local file `authors-all.txt` will use it to search for authors' emails.

	```
	. ./scm.sh && svn log https://svn.mucommander.com/mucommander | scmExtractAuthors
	```
	

	With current `authors-all.txt` file the output will be the following:

	```
	arik.hadas = Arik Ahadas <ahadas>
	kueller = kueller <kueller>
	mariusz.jakubowski = Mariusz Jakubowski <mariusj>
	maxence = Maxence Bernard <m4xence>
	maxence.bernard = Maxence Bernard <m4xence>
	nicolas.rinaudo = Nicolas Rinaudo <nicolas@nrinaudo.com>
	(no author) = noone <noone>
	root = root <root>
	xavier = xavier <xavier>
	```

# Resources

- http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/
- http://jmsliu.com/2700/more-project-from-one-svn-repository-to-another-one.html
- http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/
- John Albin
  - https://github.com/JohnAlbin/git-svn-migrate
  - http://john.albin.net/git/git-svn-migrate
  - http://john.albin.net/git/convert-subversion-to-git
- https://bitbucket.org/atlassian/svn-migration-scripts/src
- https://github.com/dsuni/svndumpsanitizer
- http://veys.com/2010/07/24/migrating-multi-project-subversion-repositories-to-git/
- https://miria.homelinuxserver.org/svndumpsanitizer/

# Samples

- java.net

	scmExplain https://svn.java.net/svn/yanfs~svn yanfs

- sf.net (users at - https://sourceforge.net/u/<user>/wiki/Home/)

	scmExplain http://svn.code.sf.net/p/upnplibmobile/code/ upnplibmobile
	scmExplain http://svn.code.sf.net/p/farmanager/code/ farmanager

- others

    scmExplain https://svn.mucommander.com/mucommander mu
    scmExplain svn://raisercostin2.synology.me/all/projects/namek namek

- personal

	# export the entire svn project since history of one project might be scattered around
    scmExplain svn://raisercostin2.synology.me/all all
	
	# dump all svn
    scmExplain svn://raisercostin2.synology.me/all all
		scmSvnClone svn://raisercostin2.synology.me/all all-1.svn
		scmSvnDump all-1.svn all-2.svndump
		scmSvnDumpFilter all-2.svndump raisercostin-commons-3.filtered-svndump "" common personal/common personal/projects/common projects/projects/common projects/projects/raisercostin-common 
		#this didn't work
		#scmSvnDumpFilterExcluding raisercostin-commons-3.filtered-svndump raisercostin-commons-4.filtered-svndump common/trunk/trunk/bin/ common/trunk/trunk/build/ common/trunk/trunk/target/ common/trunk/trunk/CVS/ personal/projects/common/trunk/arch/
		#this will corupt files
		#svndumpfilter <raisercostin-commons-3.filtered-svndump >raisercostin-commons-4.filtered-svndump exclude common/trunk/trunk/bin/ common/trunk/trunk/build/ common/trunk/trunk/target/ common/trunk/trunk/CVS/ personal/projects/common/trunk/arch/
		scmSvnFilteredClone raisercostin-commons-4.filtered-svndump raisercostin-commons-5.svn
		scmListAuthors raisercostin-commons-5.svn > raisercostin-commons-6-authors.txt
		scmGitClone raisercostin-commons-5.svn /projects/projects/raisercostin-common raisercostin-commons-6-authors.txt raisercostin-commons-7.git
	
# Thanks

Thank you for svndumpsanitizer.

# To Do
- farmanager cannot be exported since it contains trunk in branches: http://svn.code.sf.net/p/farmanager/code/branches/far2/test/trunk/
- svndumpsanitizer doesn't work over deleted and readed resources