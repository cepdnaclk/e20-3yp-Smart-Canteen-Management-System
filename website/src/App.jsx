import { useState } from 'react'
//import reactLogo from './assets/react.svg'
//import viteLogo from '/vite.svg'
import './styles/App.css'
import Register from './pages/Registration/Register.jsx'
import { Navigate, Route, Routes } from 'react-router-dom'

import LandingPage from './pages/LandingPage/LandingPage.jsx'
import Login from './pages/Login/Login.jsx'
//import Dashboard from './pages/Dashboard/Dashboard.jsx'
//import Profile from './pages/Profile/Profile.jsx'
//import Menu from './pages/Menu/Menu.jsx'
//import OrderHistory from './pages/OrderHistory/OrderHistory.jsx'  

import ContactPage from './pages/ContactPage/ContactPage.jsx'
import AboutPage from './pages/About/About.jsx'
import ForgotPassword from './pages/ForgotPassword/ForgotPassword.jsx'
import InputOtp from './components/Otp/Otp.jsx'
import AddnewPassword from './components/AddNewPassword/AddNewPassword.jsx'
import Menu from './pages/Menu/Menu.jsx'
import MyOrders from './pages/MyOrders/MyOrders.jsx'
import Home from './pages/Home/Home.jsx'
import Shop from './components/Cart/Shop.jsx'
import Cart from './components/Cart/Cart.jsx'
import Profile from './components/Profile/Profile.jsx'


function App() {
 
  return (
    <Routes>
      
      <Route path="/register" element={<Register />} />
      <Route path='/contact' element={<ContactPage />} />
      <Route path='/about' element={<AboutPage />} />
      <Route path='/login' element={<Login/>} />
      <Route path='/landing' element={<LandingPage />} />
      <Route path='/forgot-password' element={<ForgotPassword />} />
      <Route path='/input-otp' element={<InputOtp />} />
      <Route path='/add-new-password' element={<AddnewPassword />} />
      <Route path='/menu' element={<Navigate to = "/shop" />} />
      <Route path='/myorders' element={<MyOrders/>} />
      <Route path ='/shop' element = {<Shop/>} />
      <Route path='/home' element={<Home />} />
      <Route path = '/cart' element = {<Cart/>} />
      <Route path='/profile' element= {<Profile/>} />
       </Routes>
  
  );
}

export default App
