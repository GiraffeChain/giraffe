
export function requireDefined<T>(t: T | undefined): T {
    if (t === undefined) throw ReferenceError("Element Not Defined");
    else return t;
}