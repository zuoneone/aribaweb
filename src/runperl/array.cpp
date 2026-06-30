
#include <stdio.h>
#include "array.h"
#include "utils.h"

Array::Array()
{
    mnAllocated = 0;
    mnLength = 0;
    mpStrings = NULL;
}

void Array::addItem(const char *string)
{
    if (mnLength == mnAllocated) {
        mnAllocated += 10;
        int newSize = mnAllocated * sizeof(char *);
        mpStrings = (const char **) xrealloc(mpStrings, newSize);
    }

    mpStrings[mnLength++] = string;
}

void Array::addItems(const Array &other)
{
    for (int i = 0; i < other.mnLength; i++)
        addItem(xstrdup(other.mpStrings[i]));
}

const char *Array::deleteItem(int index)
{
    if (index < 0 || index >= mnLength)
        error("array index (%d) out of bounds [0,%d)", index, mnLength);

    const char *deletedItem = mpStrings[index];

    for (int i = index; i < mnLength - 1; i++)
        mpStrings[i] = mpStrings[i + 1];

    mpStrings[--mnLength] = NULL;
    return deletedItem;
}

const char *Array::getItem(int index) const
{
    if (index < 0 || index >= mnLength)
        error("array index (%d) out of bounds [0,%d)", index, mnLength);

    return mpStrings[index];
}

const char *Array::setItem(int index, const char *string)
{
    if (index < 0 || index >= mnLength)
        error("array index (%d) out of bounds [0,%d)", index, mnLength);

    const char *old = mpStrings[index];
    mpStrings[index] = string;
    return old;
}
