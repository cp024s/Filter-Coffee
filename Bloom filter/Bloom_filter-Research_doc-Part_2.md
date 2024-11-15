### how to determine the array size, index size, max storage size, how to store it in BRAM in a FPGA ?

### Key Parameters for Bloom Filter Design

1. **Array Size (`m`)**: The total number of bits in the Bloom filter's bit array.
2. **Number of Hash Functions (`k`)**: The number of independent hash functions used.
3. **Max Number of Elements (`n`)**: The maximum number of elements you expect to store in the filter.
4. **False Positive Rate (`p`)**: The desired rate of false positives (e.g., 1%).

#### 1. Calculating Array Size (`m`)
The optimal bit array size `m` can be calculated using the formula:

\[
m = -\frac{n \cdot \ln(p)}{(\ln(2))^2}
\]

- **`n`** is the expected number of elements.
- **`p`** is the desired false positive rate.

This formula derives from the probabilistic properties of Bloom filters and ensures that the bit array is sized to meet the desired accuracy.

#### 2. Calculating the Optimal Number of Hash Functions (`k`)
The optimal number of hash functions is calculated as:

\[
k = \frac{m}{n} \cdot \ln(2)
\]

Using more hash functions than this calculated `k` can increase the risk of false positives, while fewer hash functions can result in a less accurate filter. The resulting `k` is usually rounded to the nearest integer.

#### 3. Determining Storage Requirements in BRAM
- **Bit Array Size (`m` in bits)**: Given `m` bits, you’ll need \(\frac{m}{8}\) bytes to store the array in memory. For FPGA implementation, this `m` should be split into manageable blocks to map effectively onto BRAM.
  
- **BRAM Blocks**: FPGAs typically provide BRAM blocks in fixed sizes, commonly 18Kb or 36Kb. If, for example, you require an array size of 1Mb, you would need \(\frac{1,000,000 \text{ bits}}{18,432 \text{ bits per BRAM}}\), which gives approximately 54 18Kb BRAM blocks.

- **Index Size**: To access any bit within the bit array, you need an index size of \(\log_2(m)\) bits. For instance, if `m` = 1Mb (2^20), then the index size will be 20 bits.

### Storing the Bloom Filter in FPGA BRAM

To store the Bloom filter in FPGA BRAM, follow these steps:

1. **Partition the Bit Array Across BRAM Blocks**: Divide the array `m` into segments that fit the FPGA’s BRAM structure. For example, if using 18Kb BRAMs, divide `m` so each segment is up to 18Kb in size.

2. **Implement Memory Addressing**: Use the `k` hash functions to generate addresses corresponding to bit positions in the Bloom filter. In FPGA, you can implement hashing through simple hardware-based hash functions that are quick to compute, like modular arithmetic or bitwise XOR.

3. **Mapping to BRAM Addresses**: The hash functions generate indices within the bit array that map to specific BRAM addresses. For efficient implementation:
   - Each bit within the bit array can be mapped to a unique bit within a BRAM block.
   - Use FPGA logic to extract the bit position from the BRAM word based on the hashed index.

4. **Updating and Querying**:
   - For an `insert` operation, the hash functions generate indices that map to BRAM addresses, where corresponding bits are set to 1.
   - For a `query`, check the bits at the specified indices; if all bits are set, the element may exist; if any bit is 0, the element is definitely absent.

### Example Calculation

Suppose you want a Bloom filter with the following parameters:
- `n = 1,000,000` (elements)
- `p = 0.01` (1% false positive rate)

1. **Array Size (`m`)**:
   \[
   m = -\frac{1,000,000 \times \ln(0.01)}{(\ln(2))^2} \approx 9,585,058 \text{ bits} \approx 1.2 \text{ MB}
   \]

2. **Number of Hash Functions (`k`)**:
   \[
   k = \frac{9,585,058}{1,000,000} \cdot \ln(2) \approx 7
   \]

3. **BRAM Storage**:
   - For an array size of 9.6Mb, using 18Kb BRAM blocks would require around 522 BRAM blocks. If your FPGA resources are constrained, you may need to reduce `m` or use alternative methods like hierarchical Bloom filters or approximate counting filters to lower memory requirements.

### Dynamic Reconfiguration Considerations

In FPGAs, **dynamic reconfiguration** can be applied if you need to adjust the Bloom filter parameters, such as changing `k` or resizing `m`:
- **Partial Reconfiguration**: Some FPGAs support partial reconfiguration, allowing you to adjust the bit array size or update the hash function logic without completely resetting the device.
- **Scalable or Counting Bloom Filters**: If deletions are needed, consider using a Counting Bloom filter, which replaces each bit with a counter, enabling dynamic updates.

In summary, a Bloom filter can be effectively stored in FPGA BRAM by carefully calculating the array size and hash functions, mapping the bit array across available BRAM blocks, and using FPGA logic to address and update the array. With partial reconfiguration, dynamic adaptability is possible, allowing you to modify filter parameters as needed without a full FPGA reprogram.
