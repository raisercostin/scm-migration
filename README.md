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

- http://blog.dandyer.co.uk/2010/05/17/moving-projects-from-java-net-to-github/
- http://jmsliu.com/2700/more-project-from-one-svn-repository-to-another-one.html
- John Albin
  - https://github.com/JohnAlbin/git-svn-migrate
  - http://john.albin.net/git/git-svn-migrate
  - http://john.albin.net/git/convert-subversion-to-git
- https://bitbucket.org/atlassian/svn-migration-scripts/src
- https://github.com/dsuni/svndumpsanitizer

= How to use

== Initialize

First declare some functions in your current environment

	. ./svn2git.sh

== Export in one go


== Export step by step

=== Show the steps required for a full export

The step by step approach was needed since there is often the case that there are a lot of unknowns in the transformation process.
This will allow to pick only the useful steps and interspread that with your own processings.

	scmExplain https://svn.mucommander.com/mucommander mu
	------------------
	An scmFullExport will execute:
	------------------
	scmSvnClone svn://raisercostin2.synology.me/all namek4-1.svn
	scmSvnDump namek4-1.svn namek4-2.svndump
	scmFilter namek4-2.svndump namek4-3.filtered-svndump projects projects/namek projects/darzar
	scmSvnFilteredClone namek4-3.filtered-svndump namek4-4.svn
	scmListAuthors namek4-4.svn namek4-5-authors.txt
	scmGitClone3 namek4-4.svn namek4-5-authors.txt namek4-6.git /namek


== Result

	After the final 
	Show all references:
	84ee1427ccf8239a3b11996bcf9c2269148b5c85 refs/heads/master
	7b8437b1fee54b73132b675e7814f58c9d3b8ac4 refs/heads/svn/darzar
	abbdb5fba271cad3127617c14f5fc0cc57edea08 refs/heads/svn/darzar@16
	017be8e5d7744e7a5efb0dc5b2ada277d31741b8 refs/heads/svn/darzar@491
	abbdb5fba271cad3127617c14f5fc0cc57edea08 refs/heads/svn/trunk@16
	a7a4c2c229d85538b6e8349438bc97c9d77b8e2d refs/heads/svn/trunk@18
	017be8e5d7744e7a5efb0dc5b2ada277d31741b8 refs/heads/svn/trunk@493
	c4cc41df458183d9f2334a5bb0969e41de1921f4 refs/tags/darzar-0.1-with-objectify
	223a96a5db63325af5a79271408ddb192de1e90f refs/tags/darzar-0.1-with-objectify-svn
	8623bd74dac211a17500344010d0094277e1ef55 refs/tags/darzar-0.1-with-objectify@10
	68c70b89d53bb325fbf6ec4e3b80325492fd8718 refs/tags/darzar-0.1-with-objectify@10-svn
	585183661d4df64173378a819a0b5438006c8660 refs/tags/darzar-0.1-with-objectify@18
	f16d5e4498acbcadae2392fb419591e66c679f1c refs/tags/darzar-0.1-with-objectify@18-svn
	3dcc7a5944df907bf57aed5c742cbd155d924cf2 refs/tags/darzar-0.1-with-objectify@489
	b4a52c06e43a67703dd792648bf719823158fda8 refs/tags/darzar-0.1-with-objectify@489-svn
	c0f95342e047328312f45cf70342c383419ec4ab refs/tags/darzar-0.2-with-social-secure
	685164d1abfa4bb8e5c2a357d8aa84dee0b5ae72 refs/tags/darzar-0.2-with-social-secure-svn
	8276227862c142d689243a07133bc155c54ddd23 refs/tags/darzar-0.2-with-social-secure@13
	5efcf093e2227257d6e336d2e25d9045ffc3c445 refs/tags/darzar-0.2-with-social-secure@13-svn
	90b8b6ce3e02488111c620520d5294ec42272c17 refs/tags/darzar-0.2-with-social-secure@18
	5cc5ae9fe666fad945ebe63468b5e21bcab2a595 refs/tags/darzar-0.2-with-social-secure@18-svn
	493e436ab60072e2f2aa7d35785dd180c2ab437e refs/tags/darzar-0.2-with-social-secure@489
	3756207e4c7496a75c6db792b0bb1a6cefed6dc0 refs/tags/darzar-0.2-with-social-secure@489-svn
	f425938cbf639d8b435f171bf2dead79a51e8095 refs/tags/namek-0.1
	7a211799d7301a06854cdb2f767f6cae9614f19a refs/tags/namek-0.1-svn
	ab02224fa8e437ab3e36934c836c0cde2495f4e2 refs/tags/namek-0.2
	f6ddf853f34731b387e072d367df55c33292fb0f refs/tags/namek-0.2-svn
	7183280a0cbcd0d3cff1e1aa317d9ae54f9b738e refs/tags/namek-0.3-before-formatting
	57acb9b60479d0ccba21ae89feaf188fe765a2f5 refs/tags/namek-0.3-before-formatting-svn
	c48c91efb79d429204911590a8540c7751e18527 refs/tags/namek-0.4
	af42bbfddf34c4049e8df4cb37aea5c0f4ad21cb refs/tags/namek-0.4-svn
	d5e200f5db1451663fe9960c4f1df8351a002290 refs/tags/namek-0.5
	0b2a2bb4f26ecaa55d7214386b1088b5c9674d37 refs/tags/namek-0.5-svn
	89d4dd5bf1bbd8c44db27eb6d2593e8943edd0e8 refs/tags/namek-0.5.1
	5f0a52b541fd5f0125c6e54bde00706f37e208e7 refs/tags/namek-0.5.1-svn
	bec494182a7d83d60775143872bfadaf1619d144 refs/tags/namek-0.5.2
	4dfa242a979ede918513ebb9d265e97417dc242e refs/tags/namek-0.5.2-svn
	20c2caa8a997873e9ea039fbae6ca38ff843c3d7 refs/tags/namek-0.5.3-filtering%20works
	46d96283d66b5e7e54141bc359bdc60ee3463da3 refs/tags/namek-0.5.3-filtering%20works-svn
	ed1e659fe5790398710b19e9af344225e128f19a refs/tags/namek-0.6
	b466b880b53cfef17078f11ae51f14c5cb4fc2ef refs/tags/namek-0.6-svn
	3e41a720c91b166b39d55e5a501c90c025c2e254 refs/tags/namek-0.7
	6e314df31137cf350cee21955d3ab7e621b4c410 refs/tags/namek-0.7-svn
	025b404206875655aeb01f133e066bb2c7fafe59 refs/tags/namek-0.8-filtering%20works
	f3b4ddbe4c2e7dd4ae6b954dfd075368f54eb213 refs/tags/namek-0.8-filtering%20works-svn
	Current branches:
	* master
	  svn/darzar
	  svn/darzar@16
	  svn/darzar@491
	  svn/trunk@16
	  svn/trunk@18
	  svn/trunk@493
	Current tags:
	darzar-0.1-with-objectify
	darzar-0.1-with-objectify-svn
	darzar-0.1-with-objectify@10
	darzar-0.1-with-objectify@10-svn
	darzar-0.1-with-objectify@18
	darzar-0.1-with-objectify@18-svn
	darzar-0.1-with-objectify@489
	darzar-0.1-with-objectify@489-svn
	darzar-0.2-with-social-secure
	darzar-0.2-with-social-secure-svn
	darzar-0.2-with-social-secure@13
	darzar-0.2-with-social-secure@13-svn
	darzar-0.2-with-social-secure@18
	darzar-0.2-with-social-secure@18-svn
	darzar-0.2-with-social-secure@489
	darzar-0.2-with-social-secure@489-svn
	namek-0.1
	namek-0.1-svn
	namek-0.2
	namek-0.2-svn
	namek-0.3-before-formatting
	namek-0.3-before-formatting-svn
	namek-0.4
	namek-0.4-svn
	namek-0.5
	namek-0.5-svn
	namek-0.5.1
	namek-0.5.1-svn
	namek-0.5.2
	namek-0.5.2-svn
	namek-0.5.3-filtering%20works
	namek-0.5.3-filtering%20works-svn
	namek-0.6
	namek-0.6-svn
	namek-0.7
	namek-0.7-svn
	namek-0.8-filtering%20works
	namek-0.8-filtering%20works-svn

	find . -name "namek4*"|sort
	./namek4-1.svn
	./namek4-2.svndump
	./namek4-3.filtered-svndump
	./namek4-4.svn
	./namek4-5-authors.txt
	./namek4-6.git


= Thanks

Thank you for svndumpsanitizer.