docker create --name mongo-v -v /home/andrew/dev/space/db/mongo:/data mongodb:v3.3 
docker run -d --name mongo -p 27017:27017 --volumes-from mongo-v mongodb:v3.3 --smallfiles --rest
docker create --name mongo-c mongodb:v3.3 
