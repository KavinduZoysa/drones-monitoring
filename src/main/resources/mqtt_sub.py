import paho.mqtt.client as mqttClient
import mysql.connector
import time
import json


def connect_db():
    mydb = mysql.connector.connect(
        host=HOST,
        user=USER,
        password=PASSWORD,
        database=DATABASE
    )
    db_client1 = mydb.cursor()
    print("Connection to database is : ", mydb.is_connected())
    return mydb, db_client1


## {"droneID": "000X","latitude": 6.4432,"longitude": 80.64}
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("\nConnected to broker")
        global Connected
        Connected = True
    else:
        print("\nConnection failed")


def on_disconnect(client, userdata, rc):
    if rc != 0:
        print("Unexpected disconnection.")


def update_drone_info(droneID, lat, long):
    global mydb
    global db_client
    print("When updating the table, connection to database is : ", mydb.is_connected())
    if not mydb.is_connected():
        mydb, db_client = connect_db()

    db_client.execute(sql, (droneID, lat, long, round(time.time())))
    mydb.commit()


def on_message(client, userdata, message):
    msg = str(message.payload.decode("utf-8"))
    print("Message received: " + msg)
    try:
        j = json.loads(msg)
    except ValueError as e:
        print(e)
        return

    update_drone_info(j["droneID"], j["latitude"], j["longitude"])


Connected = False

broker_address = "mqtt.senzmate.com"
port = 1883
user = "username"
password = "password"
topic = "testtopic/1"

HOST = "localhost"
USER = "root"
PASSWORD = "root"
DATABASE = "drones_monitor"
sql = "INSERT INTO drones_info (droneID, latitude, longitude, timestamp) VALUES (%s, %s, %s, %s)"

mydb, db_client = connect_db()

client = mqttClient.Client("Drone Info Receiver")
# client.username_pw_set(user, password=password)
client.on_connect = on_connect
client.on_message = on_message
client.on_disconnect = on_disconnect

client.connect(broker_address, port=port)
client.loop_start()

print("Connecting ", end='')
while not Connected:
    print(".", end='')
    time.sleep(0.1)

client.subscribe(topic)

try:
    while True:
        time.sleep(1)

except KeyboardInterrupt:
    print("exiting")
    client.disconnect()
    client.loop_stop()
    db_client.close()
