import { useState, useEffect } from "react";

function useNotifications() {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const getNotifications = async () => {
      const token = localStorage.getItem('userToken');
      if (!token) {
  setError("No authentication token found.");
  setLoading(false);
  return;
}

      try {
        const response = await fetch('http://localhost:8081/api/notifications', {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
        });
        if (response.status === 401) {
      throw new Error('Unauthorized: Please login again.');
    }
        if (!response.ok) throw new Error("Failed to fetch");
        const data = await response.json();
        setNotifications(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    getNotifications();
  }, []);

  return { notifications, loading, error };
}

export default useNotifications;



export async function fetchUser() {
    const username = localStorage.getItem('user');
    const token = localStorage.getItem('userToken');
    let balance = null;

    try {
        const response = await fetch("http://localhost:8081/api/customer/balance", {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (response.status === 401) {
    throw new Error('Unauthorized: Please login again.');
  }

        if (!response.ok) {
            throw new Error('Failed to fetch balance');
        }
        balance = await response.json();
    } catch (error) {
        console.error('Error fetching balance:', error);
    }

    return { username, balance };

    
}

export async function loadMenu() {
 // const token = localStorage.getItem('userToken');
 // if (!token) throw new Error('No authentication token found.');

  const response = await fetch('http://localhost:8081/api/menu-items', {
    method: 'GET',
    headers: {
   //   'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) throw new Error('Failed to fetch menu');

  const data = await response.json();
  return data; // Array of menu items
}


// add to cart
export async function addToCart({menuItemId,quantity,name,price}) {

    const token = localStorage.getItem('userToken');
    if (!token) {
    throw new Error('Not logged in. Please login again.');
  }

  try {
    const response = await fetch('http://localhost:8081/api/cart/add', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` // Include the JWT token
      },
      body: JSON.stringify({
        menuItemId,
        quantity,
        name,price
      })
    });

    console.log("add to cart resp : ",response);

     if (response.status === 401) {
      //localStorage.removeItem('userToken'); // Clear invalid token
      throw new Error('Session expired. Please login again.');
    }

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || 'Failed to add item to cart');
    }

    return await response.json();
  } catch (error) {
    console.error('Error adding to cart:', error);
    throw error;
  }
}


export async function getCart() {
  

  const token = localStorage.getItem('userToken');
  console.log('jwt token: ',token);
  if (!token) {
  throw new Error('Not logged in. Please login again.');
}

  try{
    const response = await fetch('http://localhost:8081/api/cart',{
    method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
         
      }
    });
    console.log("Response  ",response);

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || 'Failed to get cart items');
    }

    return await response.json();

  }catch(err){
    console.error("Error getting cart : ",err);
    throw err;
  }
}

export async function removeItemFromCart(itemId){

  const token = localStorage.getItem('userToken');
  if(!token){
    console.log('User token not found');
    throw new Error('User not authenticated');
  }

  try{
    const response = await fetch('http://localhost:8081/api/cart/remove',{
      method:'POST',
      headers:{
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({itemId: itemId})
    });
   // console.log("resp stat: ",response.status);
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || 'Failed to remove cart item');
    }

    return await response.json();

  }catch(e){
    console.log("failed to delete item");
    throw e;
  }

}

  export async function Checkout(itemId) {

    const token = localStorage.getItem('userToken');
     if(!token){
    console.log('User token not found');
    throw new Error('User not authenticated');
    }

try{
    const response = await fetch('http://localhost:8080/api/cart/checkout',{
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringfy({itemId:itemId})
        });

        if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || 'Failed to remove cart item');
    }

      return await response.json();

      }catch(e){
        console.log('Failed to checkout');
        throw e;
      }  

    }

