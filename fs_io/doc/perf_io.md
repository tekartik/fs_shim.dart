# idb_sqflite perf

2023-03-06: PC 12900K Ubuntu 22.04 Chrome

`fs_idb_sqflite_perf_test.dart`

| action | count | size | idb_0 |idb_65536 |idb_16384 |idb_1024 |idb_128 |
| ------ | ----- | ---- | --- |--- |--- |--- |--- |
| write | 100 | 2 | 1589 | 1324 | 1244 | 1229 | 1304 |
| write | 100 | 1024 | 1494 | 1423 | 1510 | 1370 | 1331 |
| write | 10 | 65536 | 175 | 158 | 199 | 168 | 224 |
| write | 5 | 1048576 | 211 | 183 | 165 | 257 | 735 |
| write | 1 | 10485760 | 327 | 288 | 260 | 461 |  |
| random write | 100 | 1 | 1374 | 18 | 11 | 17 | 17 |
| random write | 100 | 103 | 1479 | 19 | 24 | 23 | 8 |
| random write | 10 | 6554 | 177 | 17 | 16 | 8 | 15 |
| random write | 5 | 104858 | 130 | 11 | 9 | 23 | 109 |
| random write | 1 | 1048577 | 175 | 14 | 15 | 43 |  |
| read | 100 | 2 | 62 | 48 | 44 | 41 | 41 |
| read | 100 | 1024 | 73 | 45 | 43 | 40 | 37 |
| read | 10 | 65536 | 34 | 39 | 38 | 49 | 38 |
| read | 5 | 1048576 | 138 | 148 | 150 | 166 | 238 |
| read | 1 | 10485760 | 248 | 265 | 258 | 283 |  |
| random read | 100 | 1 | 9 | 9 | 8 | 6 | 6 |
| random read | 100 | 103 | 7 | 9 | 7 | 7 | 6 |
| random read | 10 | 6554 | 4 | 4 | 2 | 2 | 2 |
| random read | 5 | 104858 | 31 | 6 | 5 | 6 | 14 |
| random read | 1 | 1048577 | 63 | 7 | 7 | 9 |  |

# idb_io perf

2023-03-06: PC 12900K Ubuntu 22.04 vm

(does not mean much)

| action | count | size | idb_0 |idb_65536 |idb_16384 |idb_1024 |idb_128 |
| ------ | ----- | ---- | --- |--- |--- |--- |--- |
| write | 100 | 2 | 83 | 52 | 45 | 49 | 55 |
| write | 100 | 1024 | 60 | 51 | 47 | 42 | 135 |
| write | 20 | 65536 | 46 | 47 | 49 | 146 | 2408 |
| random write | 100 | 1 | 46 | 3 | 2 | 1 | 1 |
| random write | 100 | 103 | 37 | 2 | 2 | 1 | 8 |
| random write | 20 | 6554 | 20 | 1 | 0 | 4 | 227 |
| read | 100 | 2 | 17 | 10 | 7 | 6 | 5 |
| read | 100 | 1024 | 11 | 10 | 8 | 7 | 10 |
| read | 20 | 65536 | 27 | 35 | 34 | 41 | 70 |
| random read | 100 | 1 | 3 | 5 | 3 | 3 | 2 |
| random read | 100 | 103 | 2 | 4 | 3 | 3 | 4 |
| random read | 20 | 6554 | 0 | 0 | 2 | 6 | 35 |

# io perf

2023-03-06: PC 12900K Ubuntu 22.04 vm

| action | count | size | io |
| ------ | ----- | ---- | --- |
| write | 100 | 2 | 19 |
| write | 100 | 1024 | 10 |
| write | 10 | 65536 | 1 |
| write | 5 | 1048576 | 3 |
| write | 1 | 10485760 | 7 |
| random write | 100 | 1 | 5 |
| random write | 100 | 103 | 3 |
| random write | 10 | 6554 | 0 |
| random write | 5 | 104858 | 0 |
| random write | 1 | 1048577 | 1 |
| read | 100 | 2 | 10 |
| read | 100 | 1024 | 7 |
| read | 10 | 65536 | 0 |
| read | 5 | 1048576 | 3 |
| read | 1 | 10485760 | 7 |
| random read | 100 | 1 | 5 |
| random read | 100 | 103 | 3 |
| random read | 10 | 6554 | 0 |
| random read | 5 | 104858 | 0 |
| random read | 1 | 1048577 | 0 |