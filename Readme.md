# Type Assertions

## Why?

I wanted to know how to write an `interface`.
There isn't a way. It doesn't seem like the Zig team is interested in implementing
 such a feature. Instead, zig provides you with an extremely fluid and powerful
 type system and the `comptime` directive which helps you create any
 type "contract" you need. Theoretically, a zig programmer can write his type
 assertions at comptime. But such a type of "contract" tends to be lost in the
 details of the implementation of `comptime` code. _The rest of us_ just need
 an interface. This package tries to provide one such solution
 (and more while we are at it.)

## TODO

- [ ] contract def within a contract def
