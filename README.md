<div align="center">
    <h1>Midi interpreter</h1>
</div>

A midi file interpreter, written in just over 1000 lines of MIPS assembly.

Because [Mars](https://computerscience.missouristate.edu/mars-mips-simulator.htm) has a [syscall to play midi notes](https://eclass.hmu.gr/modules/document/file.php/TP284/%CE%95%CF%81%CE%B3%CE%B1%CF%83%CF%84%CE%AE%CF%81%CE%B9%CE%BF%20%28%CE%9F%CE%BC%CE%AC%CE%B4%CE%B5%CF%82%203%2C%204%2C%205%29/%CE%95%CF%81%CE%B3%CE%B1%CF%83%CF%84%CE%AE%CF%81%CE%B9%CE%BF%203/MIPS%20syscall%20functions.pdf),
I figured it would be interesting to create a midi file interpreter in assembly that implements most[^1] of the midi file specification.

These resources proved immensely useful in my implementation:
- [list of syscalls](https://eclass.hmu.gr/modules/document/file.php/TP284/%CE%95%CF%81%CE%B3%CE%B1%CF%83%CF%84%CE%AE%CF%81%CE%B9%CE%BF%20%28%CE%9F%CE%BC%CE%AC%CE%B4%CE%B5%CF%82%203%2C%204%2C%205%29/%CE%95%CF%81%CE%B3%CE%B1%CF%83%CF%84%CE%AE%CF%81%CE%B9%CE%BF%203/MIPS%20syscall%20functions.pdf)
- [full midi file spec](http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html#BMA1_4)
- [mips green sheet](https://courses.cs.washington.edu/courses/cse378/09au/MIPS_Green_Sheet.pdf)
- [an assortment of midi files to test with](https://bitmidi.com/)

[^1]: Currently only format 1 files are supported, but in the future format 0 will also be supported.
<details>
<summary>Video Demos (turn on sound)</summary>

[Mario Demo](https://github.com/user-attachments/assets/0aaa4431-93b3-4a3d-a66a-ad0e1433c4f8)

[Pirates Demo](https://github.com/user-attachments/assets/985f237e-469f-4fcb-bc79-55d3c4bdb821)
</details>

## Usage
- Clone this repository.

- Download [the Mars Mips simulator](https://dpetersanderson.github.io/).

- Edit `main.asm` in your editor of choice and change `Filename` to a path to a midi file, relative to the root directory.
```diff
- FileName: .asciiz "./examples/mario.mid"
+ FileName: .asciiz "./path/to/file.mid"
```
- Open Mars in the directory you cloned the repository into.

- Make sure these settings are turned on.

  ![image](https://github.com/user-attachments/assets/7d1469be-635e-4dcc-88e4-99b33c43bfd1)

- Open `src/main.asm` using `File > Open`.

- Run the program using the run button at the top of the screen.

  ![image](https://github.com/user-attachments/assets/d4feae5e-e6b3-414a-813c-f8fb8e178fce)
