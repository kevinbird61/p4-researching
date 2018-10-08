#!/usr/bin/env python

from PIL import Image, ImageColor
import sys

'''
Decode the received secret (DO NOT MODIFY)
'''
def decode(data, key, id):
    # Decode the input data and store into array
    result = []
    for i in range(0, len(data)):
        temp = data[i]
        if data[i][len(data[i]) - 1] == 'a':
            temp = data[i][0 : len(data[i]) - 1]
        temp = bytearray.fromhex(temp).decode()
        result.append(temp)
    
    # Output the decoded result
    drawPixel(result, key, id)

'''
Draw each pixel box in the image (DO NOT MODIFY)
'''
def pixelBox(pixel, x, y, size, color):
    for j in range(0, size):
        for i in range(0, size):
            pixel[y * size + j, x * size + i] = color

'''
Draw pixel image (DO NOT MODIFY)
'''
def drawPixel(data, key, id):
    # Initialize for drawing
    width = 280
    height = 280
    size = 20
    background = (255, 255, 255)

    # Initialize the output file
    image = Image.new('RGB', (width, height), background)
    pixel = image.load()
    key = ''.join(reversed(key[1 : -2]))

    # Define color in each pixel
    colourPalette = {
        'B': '#000000',
        'W': '#FFFFFF',
        'K': '#' + key,
        'G': '#A1A3A2'
    }

    # Draw pixel image
    for i in range(0, len(data)):
        for j in range (0, len(data[i])):
            if data[i][j] != 'X':
                pixelBox(pixel, i, j, size, ImageColor.getrgb(colourPalette[data[i][j]]))
    
    # Save file
    filename = './out/lab1_' + id + '.png'
    image.save(filename)

'''
Main function
'''
def main():
    # Check the input args
    if len(sys.argv) != 2:
        print('[ERROR] The format of command is WRONG')
        print('[INFO] python decoder.py <YOUR_SECRET_KEY>')
        sys.exit(1)
    else:
        if len(sys.argv[1]) != 14:
            print('[ERROR] The format of key is WRONG')
            print('[INFO] python decoder.py <YOUR_SECRET_KEY>')
            sys.exit(1)
        else:
            print('[INFO] Your key is %s' % sys.argv[1])

    # Read the received secret from file
    data = []
    key = ''
    id = ''
    with open('./out/recv_secret.txt') as file:
        for line in file:
            key = key + line[0]
            data.append(line[1 : -1])
            id = ''.join(reversed(key[0 : 7]))
    
    # Check the length of input received secret
    if key != sys.argv[1]:
        key = 'EB3323'
        id = ''
        data.clear()
        for i in range(0, 14, 2):
            data.append('4B424B424B424B574B574B574B57a')
            data.append('424B424B424B424B574B574B574Ba')
    else:
        print('[INFO] Decode successful')
    print('[INFO] Finish decoding')

    # Decode the secret
    decode(data, key[0 : 7], id)

if __name__ == '__main__':
    main()