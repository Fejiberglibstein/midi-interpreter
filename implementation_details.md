
## Variable length Number

|  bytes   |    number     |
|----------|:--------------|
| 00000000 | 00            |
| 00000040 | 40            |
| 0000007F | 7F            |
| 00000080 | 81 00         |
| 00002000 | C0 00         |
| 00003FFF | FF 7F         |
| 00004000 | 81 80 00      |
| 00100000 | C0 80 00      |
| 001FFFFF | FF FF 7F      |
| 00200000 | 81 80 80 00   |
| 08000000 | C0 80 80 00   |
| 0FFFFFFF | FF FF FF 7F   |

Table found here[^1]


#### Reading a variable length number
```c
int res;
loop:
    byte b = next_byte();
    res = (res << 7);
    t0 = b & 0x7F;
    res = res + t0;
    if (b & 0x8 == 1) {
        goto loop;
    }
return res;

```


## Struct definitions

```c
struct channel { // half-word
    byte instrument; // We only use 7 bits of this byte
    byte volume;    // We only use 7 bits of this byte
}
```

```c
struct note { // double-word
    word start; // The millisecond the note started on. 
    byte channel;    // The channel number of the note
    byte key;   // 7 bits only are used

    // Since `channel` contains the data needed for these fields, we will access
    // the channel's data when we read a start note so we can fill these fields
    // properly
    byte instrument; // 7 bits only are used
    byte volume;     // 7 bits only are used
}
```

[^1]: http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html#BM1_
[^2]: https://eclass.hmu.gr/modules/document/file.php/TP284/%CE%95%CF%81%CE%B3%CE%B1%CF%83%CF%84%CE%AE%CF%81%CE%B9%CE%BF%20%28%CE%9F%CE%BC%CE%AC%CE%B4%CE%B5%CF%82%203%2C%204%2C%205%29/%CE%95%CF%81%CE%B3%CE%B1%CF%83%CF%84%CE%AE%CF%81%CE%B9%CE%BF%203/MIPS%20syscall%20functions.pdf
[^3]: https://courses.cs.washington.edu/courses/cse378/09au/MIPS_Green_Sheet.pdf
[^4]: http://personal.kent.edu/~sbirch/Music_Production/MP-II/MIDI/midi_file_format.htm
