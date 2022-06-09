function native_add(a, b) {
    return a + b;
}

window.logger = (flutter_value) => {
   console.log({ js_context: this, flutter_value });
}