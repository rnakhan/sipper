README

Please read the docs/manual.txt and the write ups on the wiki 
https://svn.freepository.com/39e65pBOqvcQA-web/wiki to get started. 


To run with proxies on windows - 

set SIPPER_TEST_PROXY_EXTERNAL=true

srun -p 7070 -o 7068 -c nonrr_proxy.rb

srun -p 5068 -o 5067 -c nonrr_proxy.rb

srun -p 5068 -o 5067 -c nonrr_proxy.rb

and then 

set SIPPER_TEST_PROXY_EXTERNAL=
