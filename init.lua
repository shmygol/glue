-- {{{ Setup environment
local pairs = pairs
local table = {
    insert  = table.insert,
    remove  = table.remove
}
local awful = require('awful')
local capi =
{
    client = client,
    mouse = mouse,
    screen = screen,
}
local print = print -- debug purposes
-- }}
 
module("glue")

-- list of glued windows
local glued_clients = {}

-- {{{ Local functions

-- minimize all clients in glued list
local function minimize_clients_in_list (glued_list, except_client)
    if glued_list == nil then
        return nil
    end
    for k, cur_client in pairs(glued_list) do
        if (cur_client ~= except_client) then cur_client.minimized = true end
    end
    return True
end

-- get glued list index by client
local function get_list_index_by_client (given_client)
    for index, cur_list in pairs(glued_clients) do
        for k, cur_client in pairs(cur_list) do
            if cur_client == given_client then return index end
        end
    end
end

local function debug_print_list (list)
    local showen_pref = ' '
    for k, cur_client in pairs(list) do
        if cur_client.minimized == false then showen_pref = '>'
        else showen_pref = ' ' end
        print(showen_pref .. cur_client.name)
    end
end

local function debug_print_all_glued_lists ()
    for index, list in pairs(glued_clients) do
        print ('===== List with indx ' .. index .. ' =====')
        debug_print_list(list)
        print ('============================')
    end
end
-- }}}


-- {{{ Global functions
 
-- glue clients
function glue(c1, c2)
    local temp_glued_windows1 = {c1}
    local temp_glued_windows2 = {c2}
    local index1 = get_list_index_by_client(c1)
    local index2 = get_list_index_by_client(c2)
    local result = {}
    if index1 ~= nil then
        temp_glued_windows1 = glued_clients[index1]
    end
    if index2 ~= nil then
        temp_glued_windows2 = glued_clients[index2]
    end
        
    c1.minimized = false
    capi.client.focus = c1
    for k,v in pairs(temp_glued_windows1) do 
        if (v ~= c1) then v.minimized = true end
        table.insert(result, v)
    end
    for k,v in pairs(temp_glued_windows2) do 
        v.minimized = true
        table.insert(result, v)
    end
    
    if index2 ~= nil then
        glued_clients[index2] = nil
    end
    if index1 ~= nil then
        glued_clients[index1] = result
    else
        table.insert(glued_clients, result)
    end
    debug_print_all_glued_lists()
end

-- unglue client
function unglue(c)
    local glued_list = glued_clients[get_list_index_by_client (c)]
    local next_client = get_next_client_in_list(glued_list)
    next_client.minimized = false
    -- remove client from glued_list
    for k, cur_client in pairs(glued_list) do
        if cur_client == c then
            glued_list[k] = nil
        end
    end
    debug_print_all_glued_lists()
end
 
-- get the next client in the gluent list
function get_next_client_in_list(glued_list)
    local return_next = false
    local first_element = nil
    if glued_list == nil then return nil end
    for k, window in pairs(glued_list) do
        if return_next == true then
            return window
        end
        if window.minimized == false then
            return_next = true
        end
        if first_element == nil then
            first_element = window
        end
    end
    if (return_next == true) then return first_element
    else return nil end
end

-- select the next client in the gluent list
function select_next_client_in_list (c)
    local glued_list = glued_clients[get_list_index_by_client (c)]
    local next_client = get_next_client_in_list(glued_list)
    if next_client == nil then return nil end
    -- next_client.minimized = false
    next_client:swap(c)
    minimize_clients_in_list(glued_list, next_client)
    capi.client.focus = next_client
    next_client:raise()
    debug_print_all_glued_lists()
end

-- }}}
