import json
import abc
import enum
import inspect
import sys
import textwrap
from turtle import back
import types
import typing
import functools
import operator
import re
import unicodedata
from libdebug import deb
import math
import random
import time


def heap_sort(arr: list[int]):
    n = len(arr)
    offset = 0
    while offset < n:
        i = n - offset
        print(arr)
        while i > 1:
            ci = offset + i - 1
            pi = offset + int(i / 2) - 1
            if arr[ci] < arr[pi]:
                arr[ci], arr[pi] = arr[pi], arr[ci]
            i -= 1
        offset += 1
    return arr


def heap_sort(arr: list[int]):
    n = len(arr)
    i = n
    # max heap and bigger left
    while i > 1:
        pi = int(i / 2) - 1
        ci = i - 1
        if arr[pi] < arr[ci]:
            arr[pi], arr[ci] = arr[ci], arr[pi]
        if i & 1:
            if arr[ci] > arr[ci - 1]:
                arr[ci], arr[ci - 1] = arr[ci - 1], arr[ci]
            i -= 2
        else:
            i -= 1
    # move max to end to keep heap stable
    arr[0], arr[-1] = arr[-1], arr[0]

    j = n

    while j > 0:
        i = 1
        while i < j:
            ci, li, ri = i - 1, 2 * i - 1, 2 * i
            if arr[li] > arr[i]:
                arr[li], arr[i] = arr[i], arr[li]
            if arr[li] < arr[ri]:
                arr[li], arr[ri] = arr[ri], arr[li]
            else:
                break
        arr[0], arr[-i - 1] = arr[-i - 1], arr[0]


#        1
#     3        2
#  10    6    3   4
# 8 3  2


print(heap_sort([1, 3, 2, 10, 6, 3, 4, 8, 3, 2]))
exit(0)


def median_of_two_sorted_arrays(la: list, lb: list):
    na, nb = len(la), len(lb)

    if na + nb == 0:
        return None

    if na > nb:
        la, lb = lb, la
        na, nb = nb, na

    odd = bool((na + nb) & 1)

    stop = math.floor((na + nb) / 2) + 1

    ia, ib, i = 0, 0, 0

    mdi = None if odd else [None, None]

    while i < stop:
        i += 1
        if ia < na:
            if ib < nb and la[ia] > lb[ib]:
                v = lb[ib]
                ib += 1
            else:
                v = la[ia]
                ia += 1
        else:
            v = lb[ib]
            ib += 1

        mdi = v if odd else [mdi[1], v]

    return mdi if odd else (mdi[0] + mdi[1]) / 2


assert median_of_two_sorted_arrays([0], [1]) == 0.5
assert median_of_two_sorted_arrays([], []) == None
assert median_of_two_sorted_arrays([1, 2, 3], [1]) == 1.5
assert median_of_two_sorted_arrays([1, 2, 3], [1, 2]) == 2


def twoSum(n: int, ls: list[int]):
    bs = {}
    for i, a in enumerate(ls):
        if a in bs:
            return [bs[a], i]
        bs[ls - a] = i


def container_with_most_water(height: list[int]):
    '''
    双指针
    '''
    n = len(height)
    if n == 2:
        return max(height[0], height[1])
    i = 0
    j = n - 1
    w = 0
    while i < j:
        if height[i] < height[j]:
            w = max(w, height[i] * (j - i))
            i += 1
        else:
            w = max(w, height[j] * (j - i))
            j -= 1
    return w


def _3Sum(nums: list):
    nums.sort()
    # print(nums)
    n = len(nums)
    triplets = []
    i = 0
    count = 0
    last_i = None
    while i < n - 2:
        if nums[i] > 0:
            break
        if last_i != nums[i]:
            last_i = nums[i]
            k = i + 1
            j = n - 1
            last_j = None
            while j > k:
                if last_j != nums[j]:
                    last_j = nums[j]
                    v = -nums[i] - nums[j]
                    if nums[i + 1] <= v and nums[j - 1] >= v:
                        while k < j:
                            count += 1
                            if nums[k] > v:
                                k = i + 1
                                break
                            elif nums[k] == v:
                                if [nums[i], nums[k], nums[j]] not in triplets:
                                    triplets.append([nums[i], nums[k], nums[j]])
                                break
                            k += 1
                j -= 1
        i += 1
    print(len(nums), count)
    return triplets


def _3Sum(nums: list):
    triplets = []
    pos_obj = {}
    neg_obj = {}
    zero = 0
    for n in nums:
        if n < 0:
            neg_obj[-n] = neg_obj.get(-n, 0) + 1
        elif n > 0:
            pos_obj[n] = pos_obj.get(n, 0) + 1
        elif n == 0:
            zero += 1

    if zero > 2:
        triplets.append([0, 0, 0])

    pos = sorted(pos_obj.keys())
    neg = sorted(neg_obj.keys())

    for i, n in enumerate(pos):
        if zero and n in neg_obj:
            triplets.append([0, n, -n])

        if pos_obj[n] > 1 and n * 2 in neg_obj:
            triplets.append([n, n, -2 * n])

        for k in neg:
            if neg_obj[k] > 1 and n == 2 * k:
                triplets.append([n, -k, -k])
            if n - k in neg_obj and n - k > k:
                triplets.append([n, -k, k - n])
            if k - n in pos_obj and k - n > n:
                triplets.append([n, -k, k - n])
    return triplets


print(_3Sum([0, 0, 0, 0]))
print(_3Sum([-1, 0, 1, 2, -1, -4]))
print(_3Sum([-1, 0, 1, 2, -1, -4, -2, -3, 3, 0, 4]))
print(_3Sum([3, 0, -2, -1, 1, 2]))
