import json
import os
from web3 import Web3
from web3.middleware import geth_poa_middleware
from web3.exceptions import TransactionNotFound
import time

# Get the absolute path to the script directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Construct the absolute path to the JSON file
json_path = os.path.join(script_dir, '..', '..', 'data', 'json', 'combined_uen_no_status.json')

# Load the JSON data
with open(json_path, 'r') as file:
    merchants = json.load(file)

# Connect to Base Sepolia
w3 = Web3(Web3.HTTPProvider('https://base-sepolia.g.alchemy.com/v2/oZacND2ea1qQkEAP4jTgNK7jjlN0LWqA'))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

# Contract address and ABI
contract_address = '0xF64C3fA7F56b9C59010Be7a96BaB0d08055B3cfE'
contract_abi = [
        {
        "inputs": [
            {"internalType": "string", "name": "_uen", "type": "string"},
            {"internalType": "string", "name": "_entity_name", "type": "string"}
        ],
        "name": "addMerchantByAdmin",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]

# Create contract instance
contract = w3.eth.contract(address=contract_address, abi=contract_abi)

# Admin account
admin_address = '0x4dB804FF4066a22f7883d4B133762762F7dAbFBa'
admin_private_key = ''
if not admin_private_key:
    raise ValueError("PRIVATE_KEY not found in .env file")

# Function to send transaction
def send_transaction(uen, entity_name):
    nonce = w3.eth.get_transaction_count(admin_address)
    gas_price = w3.eth.gas_price
    
    while True:
        try:
            tx = contract.functions.addMerchantByAdmin(uen, entity_name).build_transaction({
                'chainId': 84532,  # Base Sepolia chain ID
                'gas': 200000,
                'gasPrice': gas_price,
                'nonce': nonce,
            })
            signed_tx = w3.eth.account.sign_transaction(tx, admin_private_key)
            tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
            return w3.eth.wait_for_transaction_receipt(tx_hash)
        except ValueError as e:
            if "replacement transaction underpriced" in str(e):
                gas_price = int(gas_price * 1.1)  # Increase gas price by 10%
                print(f"Increasing gas price to {gas_price} wei")
            elif "nonce too low" in str(e):
                nonce = w3.eth.get_transaction_count(admin_address)
                print(f"Updating nonce to {nonce}")
            else:
                raise
        except TransactionNotFound:
            print("Transaction not found. Retrying...")
            time.sleep(1)

# Upload merchants
for merchant in merchants:
    max_retries = 3
    retries = 0
    while retries < max_retries:
        try:
            receipt = send_transaction(merchant['uen'], merchant['entity_name'])
            print(f"Added merchant: {merchant['uen']} - {merchant['entity_name']}")
            print(f"Transaction hash: {receipt.transactionHash.hex()}")
            break
        except Exception as e:
            print(f"Error adding merchant {merchant['uen']}: {str(e)}")
            retries += 1
            if retries < max_retries:
                print(f"Retrying... (Attempt {retries + 1} of {max_retries})")
                time.sleep(2)  # Wait for 2 seconds before retrying
            else:
                print(f"Failed to add merchant {merchant['uen']} after {max_retries} attempts")

print("Upload complete")