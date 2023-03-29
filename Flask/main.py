from pyngrok import ngrok
import os 

ngrokToken = input("Enter your ngrok authtoken:")
    


ngrok.set_auth_token(ngrokToken)

http_tunnel = ngrok.connect(3006, "http")


print("Public URL:", http_tunnel.public_url)


input("Press Enter to stop the ngrok tunnel...")

# Stop the tunnel and cleanup
ngrok.disconnect(http_tunnel.public_url)
ngrok.kill()




