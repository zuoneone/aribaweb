

#ifndef _ARRAY_H
#define _ARRAY_H

// Simple vector object, nothing fancy, it gets the job done.
// Does not manage memory very well, does not free anything,
// nor does it do anything about a copy constructor.

struct Array {
    Array();

    int length() const;
        // Returns the current number of items in the array.

    void addItem(const char *string);
        // Adds the given string to the end of the array.  <string> is NOT
        // copied, if necessary the caller must xstrdup it.

    void addItems(const Array &other);
        // Adds a copy of each item in <other>.

    const char *deleteItem(int index);
        // Removes and returns the item at the given index, shifting the
        // remaining items one position to the left.

    const char *getItem(int index) const;
        // Returns the item at index <index>, throws an error if <index> is
        // outside of the bounds of the array.

    const char *operator[](int index) const;
        // Same as getItem(index).

    const char *setItem(int index, const char *string);
        // Sets the item at <index> to <string> and returns the old value.

    const char **getItems() const;
        // Returns the vector of string pointers for calling exec etc.

private:
    int mnAllocated;
    int mnLength;
    const char **mpStrings;
};

inline int Array::length() const
    { return mnLength; }

inline const char *Array::operator[](int index) const
    { return getItem(index); }

inline const char **Array::getItems() const
    { return mpStrings; }

#endif
