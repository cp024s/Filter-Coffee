import os
import argparse
import json
import math

#Class for Bloom filter, using jenkins hash function
class BloomFilter(object):

    def __init__(self, no_of_rules, fp_prob, ipAndProtocolList, srcPortList, dstPortList, memfiles_loc):
        
        #items_count : (int) Number of rules expected to be stored in bloom filter
        # fp_prob : (float) False Positive probability in decimal given in the user_constraint file
        
        # False positive probability in decimal
        self.fp_prob = fp_prob

        # Size of bit array to use
        self.size = 8 # To be changed later. 
        #self.get_size(no_of_rules, fp_prob)

        # number of hash functions to use
        self.hash_count = self.get_hash_count(self.size, no_of_rules)
        self.ipAndProtocolList = ipAndProtocolList
        self.dstPortList = dstPortList        
        self.srcPortList = srcPortList
        self.memfiles_loc = memfiles_loc
        self.no_of_rules = no_of_rules
        
    def generateMemory(self):
        mem_array=[]
        str1=0
        bitsReqd = int(math.ceil(math.log(self.size,2)))
        memSize = (1 << bitsReqd);
        for i in range(memSize):
            mem_array.append(str1)
        for i in range(self.no_of_rules):
            k0= int("{0:08b}".format(int(self.ipAndProtocolList[0][i]))+"{0:08b}".format(int(self.ipAndProtocolList[1][i]))+"{0:08b}".format(int(self.ipAndProtocolList[2][i]))+"{0:08b}".format(int(self.ipAndProtocolList[3][i])),2)
            k1= int("{0:08b}".format(int(self.ipAndProtocolList[4][i]))+"{0:08b}".format(int(self.ipAndProtocolList[5][i]))+"{0:08b}".format(int(self.ipAndProtocolList[6][i]))+"{0:08b}".format(int(self.ipAndProtocolList[7][i])),2)
            k2= int("{0:08b}".format(int(self.ipAndProtocolList[8][i])),2)
            k01=int("{0:016b}".format(int(self.srcPortList[0][i]))+"{0:016b}".format(int(self.dstPortList[0][i])),2)
            self.add_rule(k0,k1,k2,k01,mem_array)    
        
        path=self.memfiles_loc
        if(os.path.isdir(path) is False):
            os.mkdir(path)        
        outfile = open(path+"/bloomfilter" + ".mem","w+")
        str1="0 "
        str2="1 "
        for i in range(0,memSize):
            if(mem_array[i]==1):
                outfile.write(str2)
            else:
                outfile.write(str1)

        outfile.close()    
        return [memSize, self.hash_count]
                
    
    # Function for adding a rule to the bloomfilter
    def add_rule(self,k0,k1,k2,k01,mem_array):
            digests = []
            bitsReqd = int(math.ceil(math.log(self.size,2)))
            memSize = (1 << bitsReqd)
            for i in range(self.hash_count):
                a0 = 0xdeadbef8
                #b0 = 0xdeadbef8
                b0 = (int("deadbef"+"{}".format(i+1),16))
                c0 = 0xdeadbef8
                
                # create digest for given rule using jenkins hash
                digest72= self.hash72(k0,k1,k2,a0,b0,c0) 
                digests.append(digest72)
                digest32= self.hash32(k01,a0,b0,c0) 
                digests.append(digest32)
                index72 = digest72 & (memSize-1)
                index32 = digest32 & (memSize-1)
                                
                # set the bit True in bit_array
                mem_array[index72] = 1
                mem_array[index32] = 1
            #print("Digests")
            #print([hex(i) for i in digests])
            return mem_array

    def get_size(self, n, p):
        m = -(n * math.log(p))/(math.log(2)**2)
        stride=math.ceil(math.log(m,2))
        return int(m)                    
    
    # Function to Return the hashkey for 72 bit input
    def hash72(self,k0,k1,k2,a0,b0,c0):
        a  = ((a0 + k0)& 0xffffffff)
        b  = ((b0+k1)& 0xffffffff)
        ck = ((k2 & 0xff))
        c  = (( ck + c0)& 0xffffffff)
        

        c1  = ((c ^ b)& 0xffffffff) 
        c11 = ((c1 - (b<<14|b>>18))& 0xffffffff)
        
        a1 = ((a ^ c11)& 0xffffffff) 
        a11 = ((a1 - (c11<<11|c11>>21))& 0xffffffff)
        
        b1 = ((b ^ a11)& 0xffffffff)
        b11= ((b1 - (a11<<25|a11>>7))& 0xffffffff)
        
        c2 = ((c11 ^ b11)& 0xffffffff)
        c21 = ((c2 - (b11<<16|b11>>16))& 0xffffffff)
        
        a2 = ((a11 ^ c21)& 0xffffffff)
        a21= ((a2 - (c21<<4|c21>>28))& 0xffffffff)
        
        b2 = ((b11 ^ a21)& 0xffffffff) 
        b21= ((b2 - (a21<<14|a21>>18))& 0xffffffff)
        
        c3 = ((c21 ^ b21)& 0xffffffff)
        c31= ((c3 - (b21<<24|b21>>8))& 0xffffffff)
        
        hashkey = c31
        return hashkey

    # Function to Return the hashkey for 32 bit input
    def hash32(self,k01,a0,b0,c0):

        a  = ((a0 + k01)& 0xffffffff)
        b  = ((b0)& 0xffffffff)
        c  = (( c0)& 0xffffffff)
        
        c1  = ((c ^ b)& 0xffffffff) 
        c11 = ((c1 - (b<<14|b>>18))& 0xffffffff)
        
        a1 = ((a ^ c11)& 0xffffffff) 
        a11 = ((a1 - (c11<<11|c11>>21))& 0xffffffff)
        
        b1 = ((b ^ a11)& 0xffffffff)
        b11= ((b1 - (a11<<25|a11>>7))& 0xffffffff)
        
        c2 = ((c11 ^ b11)& 0xffffffff)
        c21 = ((c2 - (b11<<16|b11>>16))& 0xffffffff)
        
        a2 = ((a11 ^ c21)& 0xffffffff)
        a21= ((a2 - (c21<<4|c21>>28))& 0xffffffff)
        
        b2 = ((b11 ^ a21)& 0xffffffff) 
        b21= ((b2 - (a21<<14|a21>>18))& 0xffffffff)
    
        c3 = ((c21 ^ b21)& 0xffffffff)
        c31= ((c3 - (b21<<24|b21>>8))& 0xffffffff)
        
        hashkey = c31
        return hashkey

    # Function to Return the size of the bloomfilter(m) to be used                
    @classmethod
    def get_size(self, n, p):
        m = -(n * math.log(p))/(math.log(2)**2)
        stride=math.ceil(math.log(m,2))
        #print("m1:",m)
        #print("stride:",stride)
        return int(m)
    
    # Function to Return the no of hash functions(k) to be used
    @classmethod
    def get_hash_count(self, m, n):
        k = round((m/n) * math.log(2))
        return int(k)


def main():
        parser = argparse.ArgumentParser()    
        parser.add_argument("-r", help="Path to rule file", required=True)
        args = parser.parse_args()
        rules_file = args.r

        rfile_handle = open(rules_file,"r")
        ruleSet = json.load(rfile_handle)["rules"]

        no_of_rules=len(ruleSet)
        memfilespath = os.getcwd()
        print("No. of rules:"+str(no_of_rules))
        print("Mem path"+str(memfilespath))
        srcPortList = getSrcPortList(ruleSet)
        dstPortList = getDstPortList(ruleSet)
        ipProtocolLists = getIPAndProtocolLists(ruleSet)
        fp_accepted = 0.1 #namesake
        bloom1=BloomFilter(no_of_rules, fp_accepted, ipProtocolLists, srcPortList, dstPortList, memfilespath)
        [m, k] = bloom1.generateMemory()


def getIPAndProtocolLists(rules):
# 1 Rule is represented by 9 Decimal Values 4 each of Src IP and Dst IP and 1 of Protocol field
        # The loop converts decimal value of Src IP, Dst IP, Protocol from header fields into binary values and merges them to produce 72 bit rule
    src_ip_field0 = []
    src_ip_field1 = []
    src_ip_field2 = []
    src_ip_field3 = []
    dst_ip_field0 = []
    dst_ip_field1 = []
    dst_ip_field2 = []
    dst_ip_field3 = []
    protocol = []
    no_of_rules = len(rules)
    for i in range(no_of_rules):
        src_ip_fields = rules[i]["src_ip"].split(".")
        src_ip_field0.append(src_ip_fields[0])
        src_ip_field1.append(src_ip_fields[1])
        src_ip_field2.append(src_ip_fields[2])
        src_ip_field3.append(src_ip_fields[3])

        dst_ip_fields = rules[i]["dst_ip"].split(".")
        dst_ip_field0.append(dst_ip_fields[0])
        dst_ip_field1.append(dst_ip_fields[1])
        dst_ip_field2.append(dst_ip_fields[2])
        dst_ip_field3.append(dst_ip_fields[3])

        protocol.append(rules[i]["protocol"])

    return [src_ip_field0,src_ip_field1,src_ip_field2,src_ip_field3,dst_ip_field0,dst_ip_field1,dst_ip_field2,dst_ip_field3,protocol]

def getSrcPortList(rules):
    srcPortList = []
    no_of_rules = len(rules)
    for i in range(no_of_rules):
        srcPortList.append(rules[i]["src_port_min"])

    return [srcPortList]

def getDstPortList(rules):
    dstPortList = []
    no_of_rules = len(rules)
    for i in range(no_of_rules):
        dstPortList.append(rules[i]["dst_port_min"])

    return [dstPortList]

if __name__ == "__main__":
    main()

