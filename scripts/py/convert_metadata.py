import json
from unittest.mock import mock_open, patch

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
    ValueError: integer must non-negative
    """
    if integer < 0:
        raise ValueError("integer must non-negative")
    return {"int": integer}

def to_hex(string: str) -> str:
    """
    Returns the hexencoded version of a string.
    
    >>> to_hex('Hello, world!')
    '48656c6c6f2c20776f726c6421'
    >>> to_hex('Python')
    '507974686f6e'
    """
    return string.encode().hex()

def byte_obj(string: str) -> dict:
    """
    If the string is greater than the max length then it will return a list of
    byte objects else it will just be the bytes object.
    
    >>> byte_obj("")
    {'bytes': ''}
    >>> byte_obj("acab")
    {'bytes': 'acab'}
    >>> byte_obj("acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789")
    {'list': [{'bytes': 'acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe0123456789acabbeeffacecafe01234567'}, {'bytes': '89'}]}
    """
    # if string is longer than accepted length then create list of strings
    max_length = 128
    if len(string) > max_length:
        string_list = [string[i:i+max_length] for i in range(0, len(string), max_length)]
        list_object = []
        for value in string_list:
            list_object.append({"bytes": value})
        return {"list": list_object}
    return {"bytes": string}

def dict_obj(data: dict, key: str) -> dict:
    """
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
    nested_map = {"map":[]}
    for nested_key in data[key]:
        # dict of strings
        if isinstance(data[key][nested_key], str):
            nested_map["map"].append({"k": byte_obj(to_hex(nested_key)), "v":byte_obj(to_hex(data[key][nested_key]))})

        # dict of ints
        elif isinstance(data[key][nested_key], int):
            nested_map["map"].append({"k": byte_obj(to_hex(nested_key)), "v":int_obj(data[key][nested_key])})
        
        # dict of lists
        elif isinstance(data[key][nested_key], list):
            nested_map["map"].append(list_obj(data[key], nested_key))
        
        # dict of dicts
        elif isinstance(data[key][nested_key], dict):
            nested_map["map"].append({"k": byte_obj(to_hex(nested_key)), "v":dict_obj(data[key], nested_key)})
            
    return nested_map


def list_obj(data: dict, key: str) -> dict:
    """
    >>> list_obj({'a':[0,1,2]}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'int': 0}, {'int': 1}, {'int': 2}]}}
    >>> list_obj({'a':['0','1','2']}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'bytes': '30'}, {'bytes': '31'}, {'bytes': '32'}]}}
    >>> list_obj({'a':[{'a':'0'},{'b':'1'}]}, 'a')
    {'k': {'bytes': '61'}, 'v': {'list': [{'map': [{'k': {'bytes': '61'}, 'v': {'bytes': '30'}}]}, {'map': [{'k': {'bytes': '62'}, 'v': {'bytes': '31'}}]}]}}
    """
    # default it to the empty list object
    if len(data[key]) == 0:
        return {"k": byte_obj(to_hex(key)),"v":{"list": []}}
    
    # list of dicts
    elif isinstance(data[key][0], dict):
        list_of_dicts = []
        for i, value in enumerate(data[key]):
            list_of_dicts.append(dict_obj(data[key], i))
        return {"k": byte_obj(to_hex(key)),"v":{"list": list_of_dicts}}
        
    # list of strings
    elif isinstance(data[key][0], str):
        list_object = []
        for value in data[key]:
            list_object.append({"bytes": to_hex(value)})
        return {"k": byte_obj(to_hex(key)),"v":{"list": list_object}}
    
    # list of ints
    elif isinstance(data[key][0], int):
        list_object = []
        for value in data[key]:
            list_object.append({"int": value})
        return {"k": byte_obj(to_hex(key)),"v":{"list": list_object}}
    
    # list of lists?
    # TODO

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
    ValueError: Invalid JSON content in the file.
    """
    try:
        with open(file_path) as f:
            data = json.load(f)
        return data
    except FileNotFoundError:
        # Handle the case when the file does not exist
        raise
    except json.JSONDecodeError:
        # Handle the case when the file contains invalid JSON content
        raise ValueError("Invalid JSON content in the file.")

def write_metadatum_file(file_path: str, data: dict):
    """
    JSON dump data into a file.
    """
    with open(file_path, "w") as f:
        json.dump(data, f)


def create_metadatum(path: str, tag: str, pid: str, tkn: str, version: int) -> dict:
    """
    Attempt to create a metadatum from a standard 
    """
    metadatum = {
        "constructor": 0,
        "fields": []
    }
    
    version_object = {"int": version}
    map_object = {"map":[]}
    
    data = read_metadata_file(path)
    
    try:
        metadata = data[tag][pid][tkn]
    except KeyError:
        # return the empty metadatum
        metadatum['fields'].append(map_object)
        metadatum['fields'].append(version_object)
        return metadatum

    # loop everything in the metadata
    for key in metadata:
        # string conversion
        if isinstance(metadata[key], str):
            map_object["map"].append({"k": byte_obj(to_hex(key)), "v":byte_obj(to_hex(metadata[key]))})

        # int conversion
        elif isinstance(metadata[key], int):
            map_object["map"].append({"k": byte_obj(to_hex(key)), "v":int_obj(metadata[key])})
        
        # list conversion
        elif isinstance(metadata[key], list):
            map_object["map"].append(list_obj(metadata, key))

        # dict conversion
        elif isinstance(metadata[key], dict):
            map_object["map"].append({"k": byte_obj(to_hex(key)),"v":dict_obj(metadata, key)})
        
        # catch whatever
        else:
            raise TypeError("Something that is not a str, int, list, or dict")
            
    # add the fields to the metadatum
    metadatum['fields'].append(map_object)
    metadatum['fields'].append(version_object)
    
    return metadatum


def convert_metadata(file_path: str, datum_path: str, tag: str, pid: str, tkn: str, version: int):
    """
    Convert the metadata file into the correct metadatum format. This would
    probably be the function to call.
    """
    datum = create_metadatum(file_path, tag, pid, tkn, version)
    write_metadatum_file(datum_path, datum)



if __name__ == "__main__":
    import doctest
    doctest.testmod()
    
    
    # made up data
    file_path = "../data/meta/example.metadata.json"
    datum_path = "../data/meta/example.metadatum.json"
    tag = '721'
    pid = '<policy_id_hex>'
    tkn = '<asset_name_ascii>'
    version = 1
    convert_metadata(file_path, datum_path, tag, pid, tkn, version)
    
    # real life newm_0 data
    file_path = "../data/meta/example.metadata2.json"
    datum_path = "../data/meta/example.metadatum2.json"
    tag = '721'
    pid = '46e607b3046a34c95e7c29e47047618dbf5e10de777ba56c590cfd5c'
    tkn = 'NEWM_0'
    version = 1
    convert_metadata(file_path, datum_path, tag, pid, tkn, version)
    
    # simple fake data
    file_path = "../data/meta/example.metadata3.json"
    datum_path = "../data/meta/example.metadatum3.json"
    tag = '721'
    pid = 'policy_id'
    tkn = 'token_name'
    version = 1
    convert_metadata(file_path, datum_path, tag, pid, tkn, version)
   