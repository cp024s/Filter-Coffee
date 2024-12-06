def rotl32(x, r):
    """Left rotate a 32-bit integer x by r positions."""
    return ((x << r) & 0xFFFFFFFF) | (x >> (32 - r))

def murmurhash3(ip_address, seed):
    """Compute the MurmurHash3 for a given IP address and seed."""
    c1 = 0xcc9e2d51
    c2 = 0x1b873593

    # Convert IP address to a 32-bit integer
    if isinstance(ip_address, str):
        parts = map(int, ip_address.split('.'))
        ip_int = (next(parts) << 24) | (next(parts) << 16) | (next(parts) << 8) | next(parts)
    else:
        ip_int = ip_address  # Use as is if already a 32-bit integer

    k = ip_int
    k = (k * c1) & 0xFFFFFFFF
    k = rotl32(k, 15)
    k = (k * c2) & 0xFFFFFFFF

    h = seed
    h = h ^ k
    h = rotl32(h, 13)
    h = (h * 5 + 0xb1e6c9e8) & 0xFFFFFFFF

    h = h ^ 4
    h = h ^ (h >> 16)
    h = (h * 0x85ebca6b) & 0xFFFFFFFF
    h = h ^ (h >> 13)
    h = (h * 0xc2b2ae35) & 0xFFFFFFFF
    h = h ^ (h >> 16)

    return h

# Generate the COE file with radix 32 (hexadecimal)
def generate_coe(ip_list, seed, coe_file):
    with open(coe_file, 'w') as f:
        f.write("memory_initialization_radix=32;\n")  # Set radix to 32 for hexadecimal
        f.write("memory_initialization_vector=\n")
        for i, ip in enumerate(ip_list):
            hash_value = murmurhash3(ip, seed)
            hex_hash = f"{hash_value:08x}"  # Convert to 8-digit hexadecimal (32-bit)
            if i < len(ip_list) - 1:
                f.write(hex_hash + ",\n")  # Add comma for all except the last element
            else:
                f.write(hex_hash + "\n")  # No comma for the last element
        f.write(";\n")

# Example usage
ip_addresses = ["192.168.1.1", "10.0.0.1", "172.16.0.1", "127.0.0.1"]  # Replace with your IP list
seed = 0x12345678  # Replace with your seed value
coe_file_path = "murmurhash3_bram_init.coe"  # Output COE file path

generate_coe(ip_addresses, seed, coe_file_path)
print(f"COE file generated at: {coe_file_path}")
