fn main(a: Field, b: Field, result: pub Field) {
    assert(a * b == result);
}

#[test]
fn test_main() {
    main(2, 5, 10);
}