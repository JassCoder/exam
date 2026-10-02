#include <unistd.h>

int main(int c, char **v)
{
    if (c != 2)
    {
        write(1, "\n", 1);
        return 0;
    }
    int i = 0;

    while (v[1][i] == ' ' || v[1][i] == '\t')
        i++;
    while (v[1][i] && (v[1][i] != ' ') && (v[1][i] != '\t'))
    {
        write(1, &v[1][i], 1);
        i++;
    }
    write(1, "\n", 1);
    return (0);
}
