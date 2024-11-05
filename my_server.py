
import socket, ssl
from threading import Thread


serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
host = "111.111.111.11" # local ipv4 address, as seen in cmd > ipconfig > ipv4
port = 24836
secret_key = b'58RiNFG-2LEjRqkfVcCv-d5euem2LOxFBp0VaD_ft_M='

serversocket.bind((host, port))

class client(Thread):
    def __init__(self, socket, address):
        Thread.__init__(self)
        self.sock = socket
        self.addr = address
        self.start()

    def run(self):
        while True:
            try:
                message = self.sock.recv(1024)
                if not message:
                    break
                print('Client:', decrypted_message.decode())
                self.sock.send(encrypted_response)
            except ConnectionResetError:
                print(f'Client disconnected')
                break
        self.sock.close()

serversocket.listen(5)
print(f'Server started and listening on {host}:{port}')
while True:
    clientsocket, address = serversocket.accept()
    print(f'New client connected: {address[0]}:{address[1]}')
    client(clientsocket, address)