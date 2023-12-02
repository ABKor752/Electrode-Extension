import subprocess

class RunData:
    def __init__(self, num_requests, time):
        self.num_requests = num_requests
        self.runtime = time
        self.tputK = (self.num_requests / self.runtime) / 1000
        self.medianLat = -1
        self.tailLat = -1


    def __str__(self):
        # result = 'REQUESTS = ' + str(self.num_requests) + "; "
        # result += 'RUNTIME (sec) = ' + str(self.runtime) + "; "
        # result += 'THROUGHPUT (K reqs/sec) = ' + str(round(self.tputK, 3)) + "; "
        # result += 'LATENCY (us) (Median) = ' + str(self.medianLat) + "; "
        # result += 'LATENCY (us) (Tail/99th) = ' + str(self.tailLat)
        # return result
        result = ''
        for val in [self.num_requests, self.runtime, round(self.tputK, 3), self.medianLat, self.tailLat]:
            result += str(val) + ','
        return result[:-1]

def run_transaction(num_clients, num_requests):
    rundata = []
    counter1 = 0
    counter2 = 0
    result = subprocess.run(
        ["./bench/client", "-c", "config.txt", "-m", "vr", "-n", str(num_requests), "-t", str(num_clients)],
        capture_output=True,
        text=True
    )
    for line in result.stderr.splitlines():
        index = line.find("Completed ")
        if (index != -1 and str(line[index + 10]).isdigit()):
            words = line[index:].split()
            time = float(words[4])
            assert words[1] == str(num_requests), 'ERROR: Num requests is ' + words[1] + ' when the number sent was ' + str(num_requests)
            rundata.append(RunData(num_requests, time))
        index = line.find("Median ")
        if (index != -1):
            rundata[counter1].medianLat = int(line[index:].split()[3]) / 1000
            counter1 += 1
        index = line.find("99th")
        if (index != -1):
            rundata[counter2].tailLat = int(line[index:].split()[4]) / 1000
            counter2 += 1

    for elt in rundata:
        print(elt)


if __name__ == '__main__':
    for num_clients in range(1, 8):
        for num_requests in range(10000, 60000, 10000):
            run_transaction(num_clients, num_requests)