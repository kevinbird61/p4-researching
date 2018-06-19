# Troubleshooting

## Q: chechsum state problem 

If your p4 compiler was in an old version, then it will show the error msg when you compile: 

```sh
INT/int-transit.p4(319): error: : not a compile-time constant when binding to checksum_state
        ck.set_state(meta.fwd_metadata.checksum_state);
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
/usr/local/share/p4c/p4include/psa.p4(352)
  void set_state(bit<16> checksum_state);
```

### A: Append the `in` direction to psa.p4

* use `vim` or other editor to open `/usr/local/share/p4c/p4include/psa.p4`, and then find the `void set_state(bit<16> checksum_state);`
* And then add `in`, the modified version: `void set_state(in bit<16> checksum_state);`
* Or you can update your p4 compiler version.