= Usage

1. Extract authors

	If the script finds a local file `authors-all.txt` will use it to search for authors' emails.

	```
	. ./migrate.sh && svn log https://svn.mucommander.com/mucommander | scmExtractAuthors
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

2. 

= Other projects
https://github.com/JohnAlbin/git-svn-migrate