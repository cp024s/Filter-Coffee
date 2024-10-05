### 3 States (BSV Wrapper):

1. **READY_STATE**:
   - Waits for the hash to be computed.
   - Passes IP protocol components (such as source/destination ports) to the hash computer.
   - Transitions to `WAIT_STATE` after passing the inputs.

2. **WAIT_STATE**:
   - Ready to accept new inputs.
   - Checks if the hash computation is valid.
   - If valid, it requests the BRAM for the result.
   - Stays in `WAIT_STATE` if the hash is still being computed.
   - Transitions to `GET_RESULT_STATE` once the hash is valid.

3. **GET_RESULT_STATE**:
   - The hash has been computed, and the result from BRAM is ready for retrieval.
   - Logs entry into the `GET_RESULT_STATE`.
   - Retrieves the result from BRAM.
   - Transitions back to `READY_STATE` after retrieving the result.

---

### Hash Computation

- Hash computation follows **6 stages** (`C1` to `C6`), performing bitwise operations on the input data to generate the final hash key.
- **States**:
  - Transitions from **Ready > C1 > C2 > C3 > C4 > C5 > C6**.
  - The final hash key is produced in the `C6` state, making the hash ready for use.

---

### Ready States in Firewall:

1. **Ready to Receive**:  
   - Checks if the firewall is ready to accept new data (i.e., in `READY_STATE`).
   
2. **Ready to Send/Transmit**:  
   - Checks if the firewall is ready to send a result or transmit data (i.e., in `GET_RESULT_STATE`).

---

### Interfaces:

1. **Firewall Interface**:
   - **pass_inps**: Passes input values (IP protocol, source port, and destination port) to the firewall.
   - **get_result**: Returns the result (whether the packet is safe or not) based on the hash lookup in BRAM.
   - **ready_recv**: Indicates if the firewall has completed processing and is ready to provide a result.

2. **Hash Interface**:
   - **put_inputs**: Accepts three input values to compute the hash.
   - **get_hash**: Returns the computed hash value.
   - **valid_hash**: Indicates whether the hash has been computed and is ready.
