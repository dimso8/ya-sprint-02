#!/bin/bash

# config server initialisation
docker compose exec -T configSrv mongosh --port 27030 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27030" }
    ]
  }
);
EOF

# shard 1 initialisation
docker compose exec -T shard11 mongosh --port 27011 <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id: 0, host: "shard11:27011"},
        { _id: 1, host: "shard12:27012"},
        { _id: 2, host: "shard13:27013"}
      ]
    }
);
EOF

# shard 2 initialisation
docker compose exec -T shard21 mongosh --port 27021 <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id: 3, host: "shard21:27021"},
        { _id: 4, host: "shard22:27022"},
        { _id: 5, host: "shard23:27023"}
      ]
    }
  );
EOF

# router initialisation
docker compose exec -T mongos_router mongosh --port 27040 <<EOF

sh.addShard( "shard1/shard11:27011");
sh.addShard( "shard2/shard21:27021");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
db.helloDoc.countDocuments() 
EOF