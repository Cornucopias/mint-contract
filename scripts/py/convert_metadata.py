import json
from typing import Tuple
from unittest.mock import mock_open, patch

# constants
MAX_LENGTH = 128


def int_obj(integer: int) -> dict:
    """
    Creates the int object.

    >>> int_obj(0)
    {'int': 0}
    >>> int_obj(123)
    {'int': 123}
    >>> int_obj(-123)
    Traceback (most recent call last):
    ...
    ValueError: Integer Must Non-Negative
    >>> int_obj(1.1)
    Traceback (most recent call last):
    ...
    ValueError: Value Must be An Integer
    """
    # positive integers
    if integer < 0:
        raise ValueError("Integer Must Non-Negative")
    
    # integers only
    if not isinstance(integer, int):
        raise ValueError("Value Must be An Integer")
    
    # simple int object
    return {"int": integer}


def to_hex(string: str) -> str:
    """
    Returns the hexencoded version of a string.

    >>> to_hex('Hello, world!')
    '48656c6c6f2c20776f726c6421'
    >>> to_hex('Python')
    '507974686f6e'
    >>> to_hex(14)
    Traceback (most recent call last):
    ...
    TypeError: Input Must Be A String
    """
    # string only
    if not isinstance(string, str):
        raise TypeError("Input Must Be A String")

    # hex encode
    return string.encode().hex()


def byte_obj(string: str) -> dict:
    """
    If the string is greater than the max length then it will return a list of
    byte objects else it will just be the byte object.

    >>> byte_obj("")
    {'bytes': ''}
    >>> byte_obj("acab")
    {'bytes': 'acab'}
    >>> byte_obj("acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789")
    {'list': [{'bytes': 'acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe01234567'}, {'bytes': '89'}]}
    >>> byte_obj(14)
    Traceback (most recent call last):
    ...
    TypeError: Input Must Be A String
    """
    # string only
    if not isinstance(string, str):
        raise TypeError("Input Must Be A String")
    
    # if string is longer than accepted length then create list of strings
    if len(string) > MAX_LENGTH:

        # split string into length 128 segments
        string_list = [string[i: i + MAX_LENGTH]
                       for i in range(0, len(string), MAX_LENGTH)]
        list_object = []

        # loop all length 128 strings
        for value in string_list:
            list_object.append({"bytes": value})

        # list of byte objects
        return {"list": list_object}

    # simple byte object
    return {"bytes": string}


def key_obj(string: str) -> dict:
    """
    Creates a proper key value object. Similar to the byte obj but it can not
    exceed the max length in hex form. So instead of auto creating a list
    it just trims the string to the max length.

    >>> key_obj("")
    {'bytes': ''}
    >>> key_obj("a short string")
    {'bytes': '612073686f727420737472696e67'}
    >>> output = key_obj("This is a very long string for testing things for the key obj testing that is longer than the max length")
    >>> len(output['bytes']) == MAX_LENGTH
    True
    >>> key_obj(14)
    Traceback (most recent call last):
    ...
    TypeError: Input Must Be A String
    """
    
    # string only
    if not isinstance(string, str):
        raise TypeError("Input Must Be A String")
    
    # the string here is in ascii since its the 721 keys
    if len(string) > MAX_LENGTH // 2:
        # trim the string down
        string = string[0:MAX_LENGTH // 2]

    # simple key object
    return byte_obj(to_hex(string))


def dict_obj(data: dict, key: str) -> dict:
    """
    This creates the dictionary object.
    
    >>> dict_obj({}, '')
    {'map': []}
    >>> dict_obj({'':{}}, '')
    {'map': []}
    >>> dict_obj({'a':{'b':0}}, 'a')
    {'map': [{'k': {'bytes': '62'}, 'v': {'int': 0}}]}
    >>> dict_obj({'a':{'b':'a'}}, 'a')
    {'map': [{'k': {'bytes': '62'}, 'v': {'bytes': '61'}}]}
    >>> dict_obj({'a':{'b':{'c':0}}}, 'a')
    {'map': [{'k': {'bytes': '62'}, 'v': {'map': [{'k': {'bytes': '63'}, 'v': {'int': 0}}]}}]}
    >>> dict_obj({'a':{'b':{'c':'a'}}}, 'a')
    {'map': [{'k': {'bytes': '62'}, 'v': {'map': [{'k': {'bytes': '63'}, 'v': {'bytes': '61'}}]}}]}
    >>> dict_obj({'a':{'b':{'c':{'d':0}}}}, 'a')
    {'map': [{'k': {'bytes': '62'}, 'v': {'map': [{'k': {'bytes': '63'}, 'v': {'map': [{'k': {'bytes': '64'}, 'v': {'int': 0}}]}}]}}]}
    """
    # dict conversion
    nested_map = {"map": []}

    # test for a valid dictionary input
    try:
        data[key]

        # if its empty return empty
        if not data[key]:
            return nested_map

    # if it doesn't exist return empty
    except KeyError:
        return nested_map

    # loop all the nested keys
    for nested_key in data[key]:
        # dict of strings
        if isinstance(data[key][nested_key], str):
            nested_map["map"].append(
                {"k": key_obj((nested_key)), "v": byte_obj(to_hex(data[key][nested_key]))})

        # dict of ints
        elif isinstance(data[key][nested_key], int):
            nested_map["map"].append(
                {"k": key_obj((nested_key)), "v": int_obj(data[key][nested_key])})

        # dict of lists
        elif isinstance(data[key][nested_key], list):
            nested_map["map"].append(list_obj(data[key], nested_key))

        # dict of dicts
        elif isinstance(data[key][nested_key], dict):
            nested_map["map"].append(
                {"k": key_obj((nested_key)), "v": dict_obj(data[key], nested_key)})

        # something that isnt a standard type
        else:
            raise TypeError("Forbidden Plutus Type")
    
    # simple dict object
    return nested_map


def list_obj(data: dict, key: str) -> dict:
    """
    This creates the list object.

    >>> list_obj({'a':[0,1,2]}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'int': 0}, {'int': 1}, {'int': 2}]}}
    >>> list_obj({'a':['0','1','2']}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'bytes': '30'}, {'bytes': '31'}, {'bytes': '32'}]}}
    >>> list_obj({'a':[{'a':'0'},{'b':'1'}]}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'map': [{'k': {'bytes': '61'}, 'v': {'bytes': '30'}}]}, {'map': [{'k': {'bytes': '62'}, 'v': {'bytes': '31'}}]}]}}
    >>> list_obj({'a':[[1,3,5],[2,4,6]]}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'list': [{'int': 1}, {'int': 3}, {'int': 5}]}, {'list': [{'int': 2}, {'int': 4}, {'int': 6}]}]}}
    >>> list_obj({'a':[[[1,3,5],[2,4,6]],[[7,9,11],[8,10,12]]]}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'list': [{'list': [{'int': 1}, {'int': 3}, {'int': 5}]}, {'list': [{'int': 2}, {'int': 4}, {'int': 6}]}]}, {'list': [{'list': [{'int': 7}, {'int': 9}, {'int': 11}]}, {'list': [{'int': 8}, {'int': 10}, {'int': 12}]}]}]}}
    """
    # default it to the empty list object
    if len(data[key]) == 0:
        return {"k": key_obj((key)), "v": {"list": []}}

    # list of dicts
    elif isinstance(data[key][0], dict):
        list_of_dicts = []
        for i, value in enumerate(data[key]):
            list_of_dicts.append(dict_obj(data[key], i))
        return {"k": key_obj((key)), "v": {"list": list_of_dicts}}

    # list of strings
    elif isinstance(data[key][0], str):
        list_object = []
        for value in data[key]:
            list_object.append({"bytes": to_hex(value)})
        return {"k": key_obj((key)), "v": {"list": list_object}}

    # list of ints
    elif isinstance(data[key][0], int):
        list_object = []
        for value in data[key]:
            list_object.append({"int": value})
        return {"k": key_obj((key)), "v": {"list": list_object}}

    # list of lists
    elif isinstance(data[key][0], list):
        list_object = []

        # loop all the lists in the list
        for l in data[key]:
            list_object.append(list_obj({'': l}, '')['v'])
        return {"k": key_obj((key)), "v": {"list": list_object}}

    # something that isnt a standard type
    else:
        raise TypeError("Forbidden Plutus Type")


def read_metadata_file(file_path: str) -> dict:
    """
    Load JSON from a file and return the data.

    >>> with patch('builtins.open', mock_open(read_data='{"name": "John", "age": 30}')):
    ...     read_metadata_file('metadata.json')
    {'name': 'John', 'age': 30}
    >>> with patch('builtins.open', mock_open(read_data='')):
    ...     read_metadata_file('empty_file.json')
    Traceback (most recent call last):
    ...
    ValueError: Invalid JSON Content In The File
    >>> read_metadata_file(14)
    Traceback (most recent call last):
    ...
    TypeError: File Path Must Be A String
    """
    
    # string only
    if not isinstance(file_path, str):
        raise TypeError("File Path Must Be A String")
    
    # attempt file read
    try:
        with open(file_path) as f:
            data = json.load(f)
        return data

    # handle the case when the file does not exist
    except FileNotFoundError:
        raise FileNotFoundError("File Does Not Exist")

    # handle the case when the file contains invalid JSON content
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON Content In The File")


def write_metadatum_file(file_path: str, data: dict) -> None:
    """
    JSON dump data into a file.

    >>> write_metadatum_file("/nonexistent/example.json", {"key": "value"})
    Traceback (most recent call last):
    ...
    OSError: Error Writing File

    >>> write_metadatum_file("../data/meta/example.json", {"key": set()})
    Traceback (most recent call last):
        ...
    TypeError: Error serializing data type
    
    >>> write_metadatum_file("../data/meta/example.json", {"key": "value"})
    >>> data = read_metadata_file("../data/meta/example.json")
    >>> data == {"key": "value"}
    True
    >>> write_metadatum_file(14, {'': ''})
    Traceback (most recent call last):
    ...
    TypeError: File Path Must Be A String
    """
    
    # string only
    if not isinstance(file_path, str):
        raise TypeError("File Path Must Be A String")
    
    # attempt file write
    try:
        with open(file_path, "w") as f:
            json.dump(data, f)

    # file path doesn't exist
    except OSError:
        raise OSError("Error Writing File")

    # data is bad
    except TypeError:
        raise TypeError("Error serializing data type")

def get_metadata_headers(file_path: str) -> Tuple[str, str, str]:
    """
    >>> file_path = "../data/meta/empty.metadata.json"
    >>> tag, pid, tkn = get_metadata_headers(file_path)
    >>> tag == "721"
    True
    >>> pid == "policy_id"
    True
    >>> tkn == "token_name"
    True
    >>> get_metadata_headers(14)
    Traceback (most recent call last):
    ...
    TypeError: File Path Must Be A String
    """
    
    # string only
    if not isinstance(file_path, str):
        raise TypeError("File Path Must Be A String")
    
    data = read_metadata_file(file_path)
    
    # TODO multitag or multitoken
    
    # single tag metadata
    tag = next(iter(data.keys())) if len(data) == 1 else None
    
    # has token and version
    pid = next(iter(data[str(tag)].keys())) if len(data[tag]) == 2 else None
    
    # just token data
    tkn = next(iter(data[tag][pid].keys())) if len(data[tag][pid]) == 1 else None
    
    # return the tuple
    return tag, pid, tkn
    

def create_metadatum(file_path: str, tag: str, pid: str, tkn: str, version: int) -> dict:
    """
    Attempt to create a metadatum from a standard 721 metadata file.

    >>> file_path = "../data/meta/empty.metadata.json"
    >>> tag = '721'
    >>> pid = 'policy_id'
    >>> tkn = 'token_name'
    >>> version = 1
    >>> create_metadatum(file_path, tag, pid, tkn, version)
    {'constructor': 0, 'fields': [{'map': []}, {'int': 1}]}

    >>> file_path = "../data/meta/readme.metadata.json"
    >>> create_metadatum(file_path, tag, pid, tkn, version)
    {'constructor': 0, 'fields': [{'map': [{'k': {'bytes': '616c62756d5f7469746c65'}, 'v': {'bytes': '4120536f6e67'}}, {'k': {'bytes': '61727469737473'}, 'v': {'list': [{'map': [{'k': {'bytes': '6e616d65'}, 'v': {'bytes': '596f75'}}]}]}}, {'k': {'bytes': '636f70797269676874'}, 'v': {'list': [{'bytes': 'c2a920323032322046616b65204c4c43'}]}}, {'k': {'bytes': '636f756e7472795f6f665f6f726967696e'}, 'v': {'bytes': '556e6974656420537461746573'}}, {'k': {'bytes': '747261636b5f6e756d626572'}, 'v': {'int': 1}}]}, {'int': 1}]}
    >>> create_metadatum(14, tag, pid, tkn, version)
    Traceback (most recent call last):
    ...
    TypeError: File Path Must Be A String
    """
    
    # string only
    if not isinstance(file_path, str):
        raise TypeError("File Path Must Be A String")
    
    # parent structure
    metadatum = {
        "constructor": 0,
        "fields": []
    }

    # set up default values
    version_object = int_obj(version)
    map_object = dict_obj({}, '')

    # get the data
    data = read_metadata_file(file_path)

    # attempt to find the metadata
    try:
        metadata = data[tag][pid][tkn]

    # return the empty metadatum if we can't find it
    except KeyError:
        metadatum['fields'].append(map_object)
        metadatum['fields'].append(version_object)
        return metadatum

    # loop everything in the metadata
    for key in metadata:
        # string conversion
        if isinstance(metadata[key], str):
            map_object["map"].append(
                {"k": key_obj((key)), "v": byte_obj(to_hex(metadata[key]))})

        # int conversion
        elif isinstance(metadata[key], int):
            map_object["map"].append(
                {"k": key_obj((key)), "v": int_obj(metadata[key])})

        # list conversion
        elif isinstance(metadata[key], list):
            map_object["map"].append(list_obj(metadata, key))

        # dict conversion
        elif isinstance(metadata[key], dict):
            map_object["map"].append(
                {"k": key_obj((key)), "v": dict_obj(metadata, key)})

        # something that isnt a standard type
        else:
            raise TypeError("Forbidden Plutus Type")

    # add the fields to the metadatum
    metadatum['fields'].append(map_object)
    metadatum['fields'].append(version_object)

    return metadatum


def convert_metadata(file_path: str, datum_path: str, tag: str, pid: str, tkn: str, version: int) -> None:
    """
    Convert the metadata file into the correct metadatum format. This would
    probably be the function to call.

    >>> file_path = "../data/meta/test.metadata.json"
    >>> datum_path = "../data/meta/test.metadatum.json"
    >>> tag = '721'
    >>> pid = 'policy_id'
    >>> tkn = 'token_name'
    >>> version = 1
    >>> convert_metadata(file_path, datum_path, tag, pid, tkn, version)
    >>> convert_metadata(13, datum_path, tag, pid, tkn, version)
    Traceback (most recent call last):
    ...
    TypeError: File Path Must Be A String
    >>> convert_metadata(file_path, 13, tag, pid, tkn, version)
    Traceback (most recent call last):
    ...
    TypeError: File Path Must Be A String
    """
    
    # string only
    if not isinstance(file_path, str):
        raise TypeError("File Path Must Be A String")
    
    # string only
    if not isinstance(datum_path, str):
        raise TypeError("File Path Must Be A String")
    
    datum = create_metadatum(file_path, tag, pid, tkn, version)
    write_metadatum_file(datum_path, datum)


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    
    
    file_path = "../data/meta/corn.metadata.json"
    datum_path = "../data/cip68/metadata-datum.json"
    tag = '721'
    pid = '<policy_id>'
    tkn = '<asset_name>'
    version = 1
    convert_metadata(file_path, datum_path, tag, pid, tkn, version)
    
