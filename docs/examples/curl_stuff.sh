    1  sudo locale-gen en_US
    2  consul members
    3  curl -v http://localhost:8500/v1/kv/
    4  curl -v http://localhost:8500/v1/kv/?recurse
    5  curl -X PUT http://localhost:8500/v1/kv/web/key1 
    6  curl -v http://localhost:8500/v1/kv/?recurse
    7  curl -X PUT http://localhost:8500/v1/kv/web/key1 -d value='dbname=naughtylist host=ec2-123-73-145-214.northpole.compute-1.amazonaws.com port=6212 user=saintnick password=ilovemrsclaus sslmode=require'
    8  curl -v http://localhost:8500/v1/kv/?recurse
    9  curl -v http://localhost:8500/v1/kv/web/key1/?raw
   10  curl -v http://localhost:8500/v1/kv/web/key1?raw
   11  curl -X PUT http://localhost:8500/v1/kv/web/key2 -d value='dbname=naughtylist host=ec2-123-73-145-214.northpole.compute-1.amazonaws.com port=6212 user=saintnick password=ilovemrsclaus sslmode=require'
   12  curl -v http://localhost:8500/v1/kv/web?keys
   13  curl -v http://localhost:8500/v1/kv/web/key1?raw
   14  curl -v http://localhost:8500/v1/kv/?recurse
   15  curl -v http://localhost:8500/v1/kv/web/key1?raw
   16  curl -X PUT http://localhost:8500/v1/kv/web/key3 -d value='{dbname:naughtylist, host:ec2-123-73-145-214.northpole.compute-1.amazonaws.com, port:6212, user:saintnick, password:ilovemrsclaus, sslmode:require}'
   17  curl -v http://localhost:8500/v1/kv/web/key3?raw
   18  curl -X PUT http://localhost:8500/v1/kv/web/key3 -d '{dbname:naughtylist, host:ec2-123-73-145-214.northpole.compute-1.amazonaws.com, port:6212, user:saintnick, password:ilovemrsclaus, sslmode:require}'
   19  curl -v http://localhost:8500/v1/kv/web/key3?raw
   20  curl -v http://localhost:8500/v1/kv/web/key3?raw | tee -a test.json
   21  cat test.json 
   22  vi t.rb
   23  apt-get install vim -y
   24  sudo apt-get install vim -y
   25  sudo apt-get update && sudo apt-get install vim -y
   26  vi t.rb
   27  ruby t.rb 
   28  which ruby
   29  vi t.rb
   30* sudo apt-cache search
   31  which ruby
   32  ruby t.rb 
   33  sudo apt-get install ruby1.9 rubygems1.9 -y
   34  sudo apt-get install rubygems1.9 -y
   35  sudo apt-get install rubygems1.9.1 -y
   36  sudo apt-get install rubygems1.9.1-full -y
   37  sudo apt-get install rubygems1.9-full -y
   38  sudo apt-get install ruby1.9.1-full -y
   39  ruby t.rb 
   40  vi t.rb
   41  ruby t.rb 
   42  ruby1.9.1 t.rb 
   43  vi t.rb
   44  ruby1.9.1 t.rb 
   45  history

curl -X POST -H "Content-Type: application/json" -d '{"username":"xyz","password":"xyz"}' http://localhost:3000/api/login

# * GOOD *
curl -X PUT http://localhost:8500/v1/kv/web/key3 -d "{\"dbname\": \"naughtylist\", \"host\": \"ec2-123-73-145-214.northpole.compute-1.amazonaws.com\", \"port\": \"6212\"}"
curl -X PUT http://localhost:8500/v1/kv/web/key4 -d "{\"dbname\": \"someval\", \"host\": \"ec2.compute-1.amazonaws.com\", \"port\": \"5555\"}"
curl -X PUT http://localhost:8500/v1/kv/web/key1 -d "{\"dbname\": \"otherval\", \"host\": \"eccccc.compute-1.amazonaws.com\", \"port\": \"4444\"}"
curl -H "Content-Type: application/json" -X PUT http://localhost:8500/v1/kv/web/key3 -d "{\"dbname\": \"naughtylist\", \"host\": \"ec2-123-73-145-214.northpole.compute-1.amazonaws.com\", \"port\": \"6212\"}"

curl -X POST -H "Content-Type: application/json" -d "{ \"key1\": \"value1\" }" 